// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_fly_io/otel_fly_io.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_fly_io-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('machines.create records cpus + memory + region', () async {
    await tracedFlyIo<String>(
      operation: 'machines.create',
      invoke: () async => const FlyIoCallResult(
        value: 'ok',
        result: FlyIoResult(
          appName: 'web',
          machineState: 'started',
          machineCpuKind: 'shared',
          machineCpus: 1,
          machineMemoryMb: 512,
          region: 'iad',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('fly_io machines.create')!);
    expect(a['fly.machine.cpus'], 1);
    expect(a['fly.machine.memory_mb'], 512);
    expect(a['fly.region'], 'iad');
  });

  test('failed machine sets span error', () async {
    await tracedFlyIo<String>(
      operation: 'machines.get',
      invoke: () async => const FlyIoCallResult(
        value: 'ok',
        result: FlyIoResult(
          machineState: 'failed',
        ),
      ),
    );
    expect(
      spans.findSpanByName('fly_io machines.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('releases.deploy records version + strategy', () async {
    await tracedFlyIo<String>(
      operation: 'releases.deploy',
      invoke: () async => const FlyIoCallResult(
        value: 'ok',
        result: FlyIoResult(
          releaseVersion: 42,
          releaseStrategy: 'rolling',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('fly_io releases.deploy')!);
    expect(a['fly.release.version'], 42);
    expect(a['fly.release.strategy'], 'rolling');
  });

  test('suppression skips spans', () async {
    await runWithoutFlyIoInstrumentationAsync(() async {
      await tracedFlyIo<String>(
        operation: 'apps.list',
        invoke: () async => const FlyIoCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('fly_io '), isEmpty);
  });
}
