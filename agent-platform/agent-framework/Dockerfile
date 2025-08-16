FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy agent code
COPY *.py ./

# Expose port
EXPOSE 8001

# Run agent service
CMD ["python", "agent_service.py"]
