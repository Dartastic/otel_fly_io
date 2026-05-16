// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_fly_io_suppression.dart';

class FlyIoResult {
  const FlyIoResult({
    this.organization,
    this.appName,
    this.appStatus,
    this.machineId,
    this.machineState,
    this.machineCpuKind,
    this.machineCpus,
    this.machineMemoryMb,
    this.machineImage,
    this.region,
    this.releaseId,
    this.releaseVersion,
    this.releaseStrategy,
    this.volumeId,
    this.volumeSizeGb,
    this.postgresClusterId,
    this.postgresStatus,
    this.litefsRegion,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? organization;
  final String? appName;
  final String? appStatus;
  final String? machineId;
  final String? machineState;
  final String? machineCpuKind;
  final int? machineCpus;
  final int? machineMemoryMb;
  final String? machineImage;
  final String? region;
  final String? releaseId;
  final int? releaseVersion;
  final String? releaseStrategy;
  final String? volumeId;
  final int? volumeSizeGb;
  final String? postgresClusterId;
  final String? postgresStatus;
  final String? litefsRegion;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

class FlyIoCallResult<T> {
  const FlyIoCallResult({required this.value, this.result});
  final T value;
  final FlyIoResult? result;
}

Future<T> tracedFlyIo<T>({
  required String operation,
  required Future<FlyIoCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (flyIoInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_fly_io');
  final span = t.startSpan('fly_io $operation', kind: SpanKind.client);
  try {
    span.setStringAttribute('rpc.system', 'fly_io');
    span.setStringAttribute('rpc.method', operation);
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.organization != null) {
        span.setStringAttribute('fly.organization', res.organization!);
      }
      if (res.appName != null) {
        span.setStringAttribute('fly.app.name', res.appName!);
      }
      if (res.appStatus != null) {
        span.setStringAttribute('fly.app.status', res.appStatus!);
      }
      if (res.machineId != null) {
        span.setStringAttribute('fly.machine.id', res.machineId!);
      }
      if (res.machineState != null) {
        span.setStringAttribute('fly.machine.state', res.machineState!);
      }
      if (res.machineCpuKind != null) {
        span.setStringAttribute('fly.machine.cpu_kind', res.machineCpuKind!);
      }
      if (res.machineCpus != null) {
        span.setIntAttribute('fly.machine.cpus', res.machineCpus!);
      }
      if (res.machineMemoryMb != null) {
        span.setIntAttribute('fly.machine.memory_mb', res.machineMemoryMb!);
      }
      if (res.machineImage != null) {
        span.setStringAttribute('fly.machine.image', res.machineImage!);
      }
      if (res.region != null) {
        span.setStringAttribute('fly.region', res.region!);
      }
      if (res.releaseId != null) {
        span.setStringAttribute('fly.release.id', res.releaseId!);
      }
      if (res.releaseVersion != null) {
        span.setIntAttribute('fly.release.version', res.releaseVersion!);
      }
      if (res.releaseStrategy != null) {
        span.setStringAttribute('fly.release.strategy', res.releaseStrategy!);
      }
      if (res.volumeId != null) {
        span.setStringAttribute('fly.volume.id', res.volumeId!);
      }
      if (res.volumeSizeGb != null) {
        span.setIntAttribute('fly.volume.size_gb', res.volumeSizeGb!);
      }
      if (res.postgresClusterId != null) {
        span.setStringAttribute(
            'fly.postgres.cluster_id', res.postgresClusterId!);
      }
      if (res.postgresStatus != null) {
        span.setStringAttribute('fly.postgres.status', res.postgresStatus!);
      }
      if (res.litefsRegion != null) {
        span.setStringAttribute('fly.litefs.region', res.litefsRegion!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('fly.error.code', res.errorCode!);
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400) ||
          res.machineState == 'failed' ||
          res.machineState == 'destroyed' ||
          res.appStatus == 'suspended' ||
          res.appStatus == 'deleted';
      if (fail) {
        span.setStringAttribute(
            ErrorResource.errorType.key, res.errorCode ?? 'fly_io.error');
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
