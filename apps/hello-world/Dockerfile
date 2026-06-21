# Stage 1: build dependencies in a heavier image
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --user --upgrade pip \
 && pip install --no-cache-dir --user -r requirements.txt

# Stage 2: slim runtime image with just what we need
FROM python:3.12-slim AS runtime

# Run as non-root for security (matches chart's containerSecurityContext)
RUN useradd --create-home --uid 1000 app
USER app
WORKDIR /home/app

# Copy installed Python packages from builder (no compilers / build tools in final image)
COPY --from=builder --chown=app:app /root/.local /home/app/.local
ENV PATH=/home/app/.local/bin:$PATH

COPY --chown=app:app main.py .

EXPOSE 8000

# uvicorn binds to all interfaces; chart's targetPort = 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
