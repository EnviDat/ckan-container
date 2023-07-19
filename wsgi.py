"""WSGI server with OpenTelemetry instrumentation."""

import os

from ckan.config.middleware import make_app
from ckan.cli import CKANConfigLoader
from logging.config import fileConfig as loggingFileConfig

# from opentelemetry import trace
# from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
# from opentelemetry.sdk.trace import TracerProvider
# from opentelemetry.sdk.trace.export import (
#     BatchSpanProcessor,
#     # ConsoleSpanExporter,
# )
# from opentelemetry.instrumentation.flask import FlaskInstrumentor

if os.environ.get("CKAN_INI"):
    config_path = os.environ["CKAN_INI"]
else:
    config_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ckan.ini")

if not os.path.exists(config_path):
    raise RuntimeError(f"CKAN config option not found: {config_path}")


# tracer = trace.get_tracer(__name__)

loggingFileConfig(config_path)
config = CKANConfigLoader(config_path).get_config()

application = make_app(config)
# Require _wsgi_app from CKANApp to access underlying flask app
# FlaskInstrumentor().instrument_app(application._wsgi_app)


# def post_fork(server, worker):
#     """For WSGI servers that spawn multiple processes (uWSGI, Gunicorn)."""
#     server.log.info("Worker spawned (pid: %s)", worker.pid)

#     trace.set_tracer_provider(TracerProvider())
#     trace.get_tracer_provider().add_span_processor(
#         BatchSpanProcessor(OTLPSpanExporter(endpoint="https://traces.envidat.ch"))
#     )
#     # Console log for debugging
#     # trace.get_tracer_provider().add_span_processor(
#     #     BatchSpanProcessor(ConsoleSpanExporter())
#     # )
