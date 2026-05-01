; PROBE 13 dip sequence after a 300s 50mA 4.5V dip @15mm
; 01-May-2026 Etches ogival point on 0.3mm SS wire
; Run once, re-zero probe on surface and run again.
G0 Z500
G0 Z-500
G0 Z500
G0 Z-500
G0 Z500
G0 Z-500
G0 Z500
G0 Z-100
G0 Z500
G0 Z-100
G0 Z500
G0 Z-100
G0 Z500
G0 Z-100
G0 Z500
G0 Z-100
G0 Z500
; Now the final finish. It gets shorter ~20um per pass
G0 Z500
G0 Z-80
G0 Z500
G0 Z-100
G0 Z500
; Keep going until the end is rounded off so much it won't contact
; in much smaller steps. May steps will miss. This is intentional.
G0 Z-102
G0 Z500
G0 Z-104
G0 Z500
G0 Z-108
G0 Z500
G0 Z-110
G0 Z500
G0 Z-112
G0 Z500
G0 Z-114
G0 Z500
G0 Z-116
G0 Z500
G0 Z-118
G0 Z500
G0 Z-120
G0 Z500
G0 Z-122
G0 Z500
G0 Z-124
G0 Z500
G0 Z-124
G0 Z500

