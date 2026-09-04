# Mindora AI Services & Models

This directory is reserved for the **Mindora AI/ML Engineering and Inference Services**.

## Overview
Mindora employs artificial intelligence models to assess motor movement, analyze speech patterns, and track attention focus during child rehabilitation sessions. This directory contains the standalone models, training pipelines, and inference microservices developed by the AI team.

## Scope & Components
- **Model Code**: Computer vision (pose estimation/movement tracking), acoustic speech analysis, and engagement tracking models.
- **Inference Services**: Standalone Python microservices (e.g., FastAPI, ONNX Runtime, PyTorch).
- **Training Artifacts & Notebooks**: Data preprocessing scripts, validation benchmarks, and training pipelines.
- **Integration Contracts**: Interface schemas and contracts defining input/output payloads exchanged with the backend.

## Architectural Boundary
> [!IMPORTANT]
> The backend orchestration and resilient fallback mechanisms remain part of `backend/src/Mindora.Infrastructure/Ai/`.
> This directory is strictly for standalone model research, training, weights, and Python inference service code.

---
*Note: AI team members will place model implementations and service code in this directory.*
