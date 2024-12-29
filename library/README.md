# RepRapMicron 3D Model Libraries

Here you will find OpenSCAD files that can be included to create "Metriccano" modular components, M3 fastener cavities, flexures, and NEMA17 mounts.

## Metriccano
This is losely-based on a metal construction toy called [https://en.wikipedia.org/wiki/Meccano]('Meccano') dating back to the late 19th Century, invented by Mr. Hornby of model railway fame. During the 20th Century it became the rapid prototyping material of choice, being familiar, available, durable, and inexpensive. It was in imperial units with BSW fasteners, and marketed as "Engineering For Boys." We have moved on a bit from that.

Metriccano is thus in metric units, using metric fasteners. The holes are spaced on a 10mm grid, the beams and plates are by default 5mm high and/or 10mm wide. The fasteners used are M3, though there is provision for 8ga countersunk woodscrews for fastening assemblies to breadboards.

The parts can be reused over several projects, providing a convenient way of recycling 3D printed prototypes. They can also be "condensed" in OpenSCAD to combine parts without the use of fasteners, or simply joined on to other OpenSCAD modules to provide convenient, standard attachment points.

Historical note: The original RepRap proof-of-concept 3D printing mechanism was made from Meccano, and so the whole thing has come full circle.

## M3 Parts
A model library of defined M3 cavity elements and measurements. If your printer prints things a bit too irregularly, or extremely precisely, and the holes don't fit your screws/nuts/bolts, then adjust the sizing here.

## NEMA17lib
Dimensions of a NEMA17 motor, for obvious reasons

# Flexbeam
A library for creating round-ended beams with vertical flexures on them. Not actually used at present, but it was handy for roughing out concepts and finding out just how wrong one can be...
