FROM python:3.11-alpine AS builder

WORKDIR /app

RUN apk add --no-cache build-base libffi-dev

COPY requirements.txt .

RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels -r requirements.txt


FROM python:3.11-alpine

WORKDIR /app

RUN apk add --no-cache curl

COPY --from=builder /wheels /wheels

RUN pip install --no-cache-dir /wheels/* \
    && rm -rf /wheels

RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
    && mkdir -p /var/log/app \
    && chown -R appuser:appgroup /app /var/log/app

COPY main.py .

RUN chown appuser:appgroup main.py

ENV LOG_FILE=/var/log/app/app.log

VOLUME ["/var/log/app"]

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://127.0.0.1:8080/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
