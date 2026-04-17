# Ogul

Ogul is a system for tracking facial changes over time using iPhone-based 3D capture and a backend processing pipeline. It quantifies swelling, asymmetry, and structural variation to enable longitudinal monitoring of post-surgical recovery.

---

## 🧠 Overview

Modern smartphones can capture high-quality 3D facial data, but existing tools focus on single snapshots rather than how faces change over time.

Ogul addresses this gap by:
- capturing consistent facial scans via iOS  
- aligning scans across time  
- computing geometric differences  
- generating time-series analytics  

> The goal is to turn raw facial scans into meaningful, trackable signals.

---

## 🏗️ System Architecture

Ogul is designed as a multi-layer system:

### 📱 Capture Layer (iOS)
- Guided facial scanning using ARKit + TrueDepth  
- Ensures consistent pose, framing, and lighting  
- Local storage and upload pipeline  

### ☁️ Backend Pipeline
- Scan ingestion and storage  
- 3D face reconstruction  
- Facial landmark detection  
- Pose normalization and alignment  
- Mesh comparison across time  

### 📊 Analytics Layer
- Facial volume change (%)  
- Left/right asymmetry  
- Surface displacement heatmaps  
- Longitudinal trend tracking  

---

## 🔄 Data Flow

1. User performs guided scan on iOS  
2. Scan data is stored locally and uploaded  
3. Backend processes and aligns scans  
4. Geometric differences are computed  
5. Analytics are returned to client  

---

## 🎯 Use Case

- Post-surgical facial swelling tracking  
- Remote patient monitoring  
- Objective recovery measurement  
- Research on facial change over time  

---

## 🚀 Goals

- Build a robust pipeline for noisy real-world 3D data  
- Enable consistent, repeatable facial measurements  
- Extract meaningful signals from time-series geometry  
- Design a scalable mobile → backend → analytics system  

---

## 🧩 Repositories

- `ogul-ios` → iOS capture client  
- `ogul-backend` → processing + analytics pipeline  

---

## 🔥 Key Idea

> Existing systems measure faces at a single point in time.  
> Ogul measures how faces change over time.

---
