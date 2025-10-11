// maus_probe.scad - Probe head components for Maus 3D Printer
// (c)2024 vik@diamondage.co.nz, released under the terms of the GPL V3 or later

version_string="MAUS V0.05";

include <../library/m3_parts.scad>
include <../library/metriccano.scad>


// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}

// This section covers the little arm that holds the probe, and the jig for assembling same.
probe_tip_thick=2.5;
probe_held_in_arm=17;   // Length of probe arm from centre of securing pivot.
probe_tip_len=23;           // Total length of a wire probe tip, butts up to the central screw

module probe_tip_arm_hull() {
    hull() {
        cylinder(h=probe_tip_thick,r=metriccano_unit/2,$fn=32);
        translate([probe_held_in_arm,0,probe_tip_thick/2])
            rotate([0,0,45]) cube(probe_tip_thick,center=true);
    }
}

// Probe tip. Now with handling notches for tweezers.
module probe_tip_arm() {
    difference() {
         probe_tip_arm_hull();
        // Retaining pivot hole
        m3_screw_hole(probe_tip_thick*3);
        // Nut well
        translate([0,0,probe_tip_thick-1]) m3_nut_cavity();
        // Notch to retain probe wire
        translate([0,-0.4,probe_tip_thick-1])
            cube([probe_held_in_arm*2,0.8,probe_tip_thick]);
        // Handling notches
        translate([0,metriccano_unit/2,0]) cube([1,1.6,10],center=true);
        translate([0,-metriccano_unit/2,0]) cube([1,1.6,10],center=true);
    }
}

// Device to hold Probe Tip Arm while you fit a probe tip to it
// V0.05 expects a ~23mm long probe when the tip is angled down at approx 45 degrees
pj_width=15;
pj_height=10;
pj_handle=25;   // Something to grab hold of
pj_length=pj_handle+metriccano_unit/2+probe_tip_len+10; // Overall jig length
pj_protective_slot=5;

module probe_assembly_jig() {
    // Dummy probe for fit test
    //%translate([m3_screw_rad,0,pj_height]) rotate([0,90,0]) cylinder(h=probe_held_in_arm,r=0.8);
    //%translate([m3_screw_rad,0,pj_height]) rotate([0,90,0]) cylinder(h=probe_tip_len,r=0.5);
    
    // Create a jig block and chop out cavity for arm, screw heads etc.
    difference() {
        // Body of jig
        translate([-pj_handle,-pj_width/2,0]) cube([pj_length,pj_width,pj_height]);
        // Hole to access screw head
        cylinder(h=pj_height*3,r=m3_screw_head_rad+0.5,center=true);
        // Recess for the arm, slightly enlarged
        translate([0,0,pj_height-probe_tip_thick]) minkowski() {
            probe_tip_arm_hull();
            sphere(0.2,$fn=16);
        }
        // Slot for probe wire to run along
        translate([0,0,pj_height-1])
            cube([pj_length*3,0.8,probe_tip_thick],center=true);
        // Notch where tip should be
        translate([probe_tip_len+m3_screw_rad,0,pj_height])
            rotate([0,45,0]) cube([0.6,pj_width*3,0.6],center=true);
        // Protective slot for probe tip
        translate([probe_held_in_arm+m3_screw_rad+pj_protective_slot/2,0,0]) {
            cylinder(h=pj_height*3,r=pj_protective_slot/2,center=true,$fn=32);
            translate([pj_length/2,0,0])
                cube([pj_length,pj_protective_slot,pj_height*3],center=true);
        }
        // Tell people what this curious thing is
        translate([5,-pj_width/2,pj_height/2])
            rotate([90,0,0]) translate([0,0,-0.3]) linear_extrude(0.6) 
            text(str(version_string," Probe Jig ",probe_tip_len,"mm"), size = 3, halign = "center", valign = "center", $fn = 16);
    }
}


// 100mm long beam for testing flexure deflection with a 10g weight (.38 cal bullet)
test_pan_rad=10; // Radius of test pan cavity for weights
test_arm_len=100;
module test_flexure() {
    flexure_tab();
    // 100mm beam with pan on the end
    difference() {
        union() {
            translate([flexure_length/2,-4,0]) cube([100,8,8]);
            translate([flexure_length/2+test_arm_len,0]) cylinder(h=10,r=test_pan_rad+wall);
            // Wee spike on the end.
            translate([flexure_length/2+test_arm_len+test_pan_rad+wall-0.5,0,0.5])
                rotate([0,0,45]) cube([4,4,1],center=true);
        }
        // Scalop it out
        translate([flexure_length/2+test_arm_len,0,1]) cylinder(h=100,r=test_pan_rad);
    }
    // Anchor plate
    translate([-flexure_length/2-metriccano_unit*1.5,-metriccano_unit/2,0]) metriccano_plate(2,2);
}

// The probe holding sytem is a complex affair. Two (reversible) brackets hold a beam
// with a slotted blade under it. A shuttle shaped a bit like a tuning fork fits astride this 
// beam, and has the Probe Tip Arm bolted to it. The bolt holes are slotted, allowing
// the probe to move up/down/back/forth and tilt.
// A screw driven in from above locks the beam in place.

probe_beam_standoff=3;  // Keep this far away from the Driver to avoid flexing flexures
pbr_clearance=0.65;      // Clearance on sliding probe beam parts (washer+0.05)
pbr_length=12;
pbr_width=metriccano_unit-2*pbr_clearance;
pbr_height=metriccano_unit-2*pbr_clearance;
pbr_blade_thick=metriccano_screw_rad*2;     // Why not make the blade fit over a screw?
pbr_blade_width=metriccano_unit;
pbr_blade_height=14;        // WAG
pbr_blade_setback=6;        // Move the blade this far off centre

probe_shuttle_length=20;    // Length of the shuttle (not including probe mount) WAG

// A runner bracket for the probe beam, attaching to the Z Axis Driver
module probe_beam_runner() {
}

// The beam that is clamped  underneath the Z Driver.
// Has a blade that the  beam shuttle attaches to.
module probe_beam() {
    difference() {
        // Body of the beam
        translate([-pbr_width/2,0,0]) cube([pbr_width,pbr_length,pbr_height]);
        // Nut slot for nut that retains the beam
        translate([0,pbr_length/2,(pbr_height-metriccano_nut_height)/2]) 
            metriccano_nut_slot();
        // Hole for the screw to access the nut
        translate([0,pbr_length/2,0]) metriccano_screw_hole(pbr_height*2-2);
    }
    // The blade that protrudes from the beam
    translate([0,-pbr_blade_setback,pbr_height]) difference() {
        // Blade body
        union() {
            translate([-pbr_blade_thick/2,0,0])
                cube([pbr_blade_thick,pbr_blade_width,pbr_blade_height]);
            // Angled lead-in to overhanging blade
            translate([-pbr_blade_thick/2,0,0]) rotate([-45,0,0]) cube([pbr_blade_thick,pbr_blade_setback*1.5,pbr_blade_setback*1.5]);
        }
        // The slot for the screw
        translate([-pbr_blade_thick*2,pbr_blade_width/2-metriccano_screw_rad,3])
            cube([pbr_blade_thick*4,metriccano_screw_rad*2,pbr_blade_height-6]);
    }
}

// The bit that holds the Probe Arm Tip and clamps onto the Probe Beam Blade
// Uses Metriccano thicknesses except for the blade slot.
module probe_shuttle() {
    difference() {
        // Body of the shuttle
        union() {
            translate([-metriccano_unit/2-0.3,0,0])
                cube([metriccano_unit+0.6,probe_shuttle_length,metriccano_unit]);
            // Mounting hole to screw the probe arm to.
            translate([0,-metriccano_unit/2,0]) rotate([0,0,180]) metriccano_tab_module(1);
        }
        // Blade slot
        translate([0,probe_shuttle_length/2,0]) 
            cube([pbr_blade_thick+2*pbr_clearance,probe_shuttle_length+0.01,metriccano_unit*3],center=true);
        // Screw slots (do not make too long, or it'll all collapse when printed...)
        translate([0,probe_shuttle_length/2,metriccano_unit/2]) 
            cube([metriccano_unit*3,probe_shuttle_length-metriccano_unit,metriccano_screw_rad*2],center=true);        
    }
}


// Probe tip and holder parts, slide holding parts.
if (true) {
    translate([50,25,0]) probe_tip_arm();
    translate([50,10,0]) probe_tip_arm();
    translate([10,10,0]) probe_beam();
    translate([35,10,0]) probe_shuttle();
    translate([30,40,0]) probe_assembly_jig();
}
