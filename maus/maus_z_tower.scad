// maus_z_tower.scad - RepRapMicron Maus tower to hold Z Axis Driver
// (C) 2025 vik@diamondage.co.nz Released under the GPLV3 or later.
// Notes:
// Requires 3 standard Maus axis drivers and probe holder parts
// Base should be secured to 10mm pitch perforated sheet, 13 x 11 holes
//  avaliable as metriccano_baseboard.svg for lasercutting
// It is a Very Good Idea(TM) to keep the width in Metriccano (10mm) units.
// Printed on Prusa Mk4, 0.2mm layers, 20% infill, 2 v shells, 5 h shells
// V0.04
//  Moved one beam and added reinforcement to avoid collisions with new X flexure.
// Z Tower one unit higher to allow tall motors to fit under the Axis Driver.
//  - No longer needs 3-unit Metriccano strips.

include <../library/metriccano.scad>

version_string="MAUSL V0.05";



// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}

module vertical_strip(units) union() {
    translate([metriccano_unit/2,0,metriccano_unit/2]) rotate([0,-90,0]) {
        metriccano_square_strip(units);
        // Seal off the first square for strength
        translate([-metriccano_unit/2,-metriccano_unit/2,0]) cube(metriccano_unit);
    }
}

// Metriccano-scaled X-shape span
module crossed_span(width) translate([metriccano_unit/2,-metriccano_unit/2,0]) {
    hull() {
        cube([0.1,metriccano_unit/2,metriccano_unit]);
        translate([metriccano_unit*width,0,metriccano_unit*width]) cube([0.1,metriccano_unit/2,metriccano_unit]);
    }
    hull() {
        translate([metriccano_unit*width,0,0]) cube([0.1,metriccano_unit/2,metriccano_unit]);
        translate([0,0,metriccano_unit*width]) cube([0.1,metriccano_unit/2,metriccano_unit]);
    }
}

union() {
    // Metriccano-based tower to support Z axis
    translate([metriccano_unit,0,0]) {
        translate([0,-metriccano_unit,0]) vertical_strip(12);        // Solid strip support
        //  Pillar closest to motor 
        translate([0,-metriccano_unit*2,0])  rotate([0,0,90]) vertical_strip(7);
        // Outside pillarto improve stability
        translate([-metriccano_unit,-metriccano_unit*2,0])  rotate([0,0,90]) vertical_strip(9);
        translate([metriccano_unit*3.5,-metriccano_unit*2.5,0]) {
            // Versioning
            translate([metriccano_unit/2,metriccano_unit/2-1,metriccano_unit*4]) rotate([0,90,0]) version_text();
            cube([metriccano_unit/2,metriccano_unit,metriccano_unit*7]);
            // Taper at top of flattened strip to avoid overhangs
            translate([0,0,metriccano_unit*6]) hull() {
                cube([0.01,metriccano_unit,0.01]);
                translate([0,0,metriccano_unit]) cube([metriccano_unit,metriccano_unit,0.01]);
            }
        }
    // Spans linking the two
     translate([0,-metriccano_unit*1,metriccano_unit*8]) crossed_span(3);
     translate([0,-metriccano_unit*1.25,metriccano_unit]) crossed_span(3);
    }
    // Angled strip that attaches to the flexure frame, at 45 degrees at the bottom
     translate([metriccano_unit*5,-metriccano_unit,0])  rotate([0,0,-45]) vertical_strip(7);
    // Twist between two square strips at 45 degrees to each other
     translate([metriccano_unit*5,-metriccano_unit,metriccano_unit*7]) difference() {
         // The twist
        hull() {
             rotate([0,0,-45]) cube([metriccano_unit,metriccano_unit,0.01],center=true);
             translate([-metriccano_unit/2,-metriccano_unit/2,metriccano_unit])
                cube([metriccano_unit,metriccano_unit,0.01]);
         }
         // Level offone side of the twist
         translate([-metriccano_unit/2,-metriccano_unit*1.5,0]) cube(metriccano_unit);
     }
     // Top of "twisted" pillar that points aling Z Axis driver
     translate([metriccano_unit*4.5,-metriccano_unit,metriccano_unit*11.5])  rotate([0,90-0,0]) metriccano_square_strip(4);

     
    // Base plate
    translate([metriccano_unit*5,-metriccano_unit,0])  rotate([0,0,135])    difference() {
        union() {
            // Nub that fits under the corner of the frame (will be perforated, with screw head cavity underneath)
            translate([metriccano_unit/2,-metriccano_unit/2,0]) cube(metriccano_unit);
            translate([-metriccano_unit,0,0])
                difference() {
                    // Create a base plate with a nub on top and section taken out of one side
                    union() {
                        metriccano_plate(7,6);
                    }
                    // Need to chop out a place for the frame to go
                    translate([metriccano_unit*2.5,-1.5*metriccano_unit,-1])
                        cube([metriccano_unit*6,metriccano_unit*2,metriccano_unit*2]);
                }
            }
            // Perforate the nub with a hole and room for screw head
            translate([metriccano_unit*1,0,]) 
                union() {
                    rotate([180,0,0]) metriccano_screw_hole(30);
                    metriccano_nut_cavity_tapered(captive=true);
                }
        }
}


