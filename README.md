# MNIT Attendance Web Application

A full-fidelity web port of the native **MNIT Attendance iOS application** built for **Google AI Studio** using **React 19**, **TypeScript**, **Vite**, and **Tailwind CSS**.

---

## Ported Features & Architecture

### 1. Front Camera Selfie & Anti-Spoofing Verification
- Real-time in-app front camera stream via HTML5 `navigator.mediaDevices.getUserMedia`
- Oval face positioning guide overlay matching `SelfieCameraModal.swift`
- Live GPS coordinate display with horizontal accuracy indicator (flags accuracy $\le 50\text{m}$)
- Automated watermark timestamp, GPS coordinates, and employee identity stamping
- Simulator / fallback capture mode for environments without camera hardware

### 2. Live Punch & Daily Shift State Machine
- Real-time ticking digital clock (`HH:mm:ss`) and formatted date
- Dynamic punch action card:
  - **Check In** (Emerald Gradient `#059669` $\to$ `#10B981`) when workday hasn't begun
  - **Check Out** (Rose Gradient `#E11D48` $\to$ `#F43F5E`) when shift is ongoing
  - **Workday Complete** card when both punches are recorded
- Today's punch log with photo thumbnail preview zoom, GPS coordinates, and sync status

### 3. Interactive Monthly Attendance Calendar
- Monthly navigation (`< Month Year >`)
- Summary metrics: Days Worked, Total Hours Worked, Declared Holidays
- Calendar grid with color-coded day indicators (Present, Holiday, Weekend, Selected)
- Day drill-down modal showing all punch events and durations for the selected date
- Official declared company holiday listings

### 4. Device Punch Log & Offline-First Sync
- Local persistence replicating iOS SQLite/Room `AttendancePunchRecord`
- Queue management with sync status pills: `SYNCED`, `PENDING`, `SYNCING`, `FAILED`
- Manual and automatic cloud synchronization
- Search and filter by status (`All`, `Synced`, `Pending`, `Failed`)

### 5. Annual Leave Quota & Application System
- Quota balance tracking: Total Assigned (12 days), Used, and Remaining
- Interactive leave application form with dynamic day-count calculation
- Leave categories: Casual Leave (CL), Medical Leave (ML), Earned Leave (EL), Compensatory Off
- Approval status tracking with supervisor review notes

### 6. Employee Profile & Hardware Diagnostics
- Official employee details (Employee ID, Email, Phone, Department, Designation, Joining Date)
- Persistent Hardware Device UID matching iOS Keychain Services
- Network mode toggle (Online Sync vs. Local Offline Storage)
