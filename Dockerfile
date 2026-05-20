# FROM python:3.11-slim

# WORKDIR /app

# # Install system dependencies needed for network utilities
# RUN apt-get update && apt-get install -y \
#     curl \
#     && rm -rf /var/lib/apt/lists/*

# # Copy requirements and install python packages
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# # Copy the rest of the application code
# COPY . .

# # Expose Streamlit's default port
# EXPOSE 8501

# # Run the streamlit application
# CMD ["streamlit", "run", "streamlit_app.py", "--server.port=8501", "--server.address=0.0.0.0"]





# Stage 1: Dependency Compiler Environment
FROM python:3.11-slim AS compiler-stage

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Production Execution Image
FROM python:3.11-slim AS production-runner

WORKDIR /app

# Safely carry over verified binary dependencies
COPY --from=compiler-stage /root/.local /root/.local
COPY . .

# Ensure environment pathways prioritize compiled python paths
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

EXPOSE 8501

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl --fail http://localhost:8501/_stcore/health || exit 1

CMD ["streamlit", "run", "streamlit_app.py", "--server.port=8501", "--server.address=0.0.0.0"]