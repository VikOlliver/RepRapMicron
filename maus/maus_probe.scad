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

// The rails that grip the probe holder and hold it to the Z axis platform
probe_holder_rail_len=metriccano_unit*4;
probe_holder_rail_width=metriccano_unit*1.5;
module probe_holder_rail() difference() {
    cube([probe_holder_rail_width,probe_holder_rail_len,probe_holder_wall]);
    // Rail that retains sliding probe holder
    translate([probe_holder_rail_width-1.2,-1,probe_holder_wall-1.2])
        cube([metriccano_unit+2,probe_holder_rail_len+2,2]);
    // Mounting holes for mating axis plate
    translate([metriccano_unit/2,metriccano_unit/2,0]) m3_screw_hole(metriccano_unit*2);
    translate([metriccano_unit/2,probe_holder_rail_len-metriccano_unit/2,0]) m3_screw_hole(metriccano_unit*2);
    // Now a cavity containg a nut, used to temporarily lock probe slide in place
    translate([probe_holder_rail_width/2,probe_holder_rail_len/2,probe_holder_wall/2])
        rotate([0,-90,0]) m3_nut_slot();
    // The screw that will lock the sliding probe arm in place
    translate([0,probe_holder_rail_len/2,probe_holder_wall/2])
        rotate([0,90,0]) m3_screw_hole(probe_holder_rail_width*3);
}

// Probe holder
probe_holder_wall=8;    // Thick enough to hide an M3 nut in
probe_holder_pivot_offset=14;   // Location of hole that holds the pivot arm on
module probe_holder() difference() {
    union() {
        // Sliding bar
        cube([metriccano_unit,probe_holder_rail_len,probe_holder_wall]);
        translate([-1,0,0]) cube([metriccano_unit+2,probe_holder_rail_len,1]);
        // Probe holder on the end of the sliding bar
        translate([metriccano_unit/2,0,probe_holder_pivot_offset]) rotate([-90,0,0]) cylinder(h=metriccano_unit/2,r=metriccano_unit/2);
        cube([metriccano_unit,metriccano_unit/2,probe_holder_pivot_offset]);
        translate([metriccano_unit/2,probe_holder_rail_len/2+2,probe_holder_wall]) rotate([0,0,90]) version_text();
    }
     // Hole to hold screw in the probe tip assembly
    translate([metriccano_unit/2,0,probe_holder_pivot_offset])
        rotate([90,0,0]) m3_screw_hole(metriccano_unit*2);
}
    

// Probe tip
probe_tip_thick=2.5;
probe_tip_len=17;   // Length of probe from centre of securing pivot.
module probe_tip_arm() difference() {
    hull() {
        cylinder(h=probe_tip_thick,r=metriccano_unit/2,$fn=32);
        translate([probe_tip_len,0,probe_tip_thick/2]) rotate([0,0,45]) cube(probe_tip_thick,center=true);
    }
    // Retaining pivot hole
    m3_screw_hole(probe_tip_thick*3);
    // Nut well
    translate([0,0,probe_tip_thick-1]) m3_nut_cavity();
    // Notch to retain probe wire
    translate([0,-0.4,probe_tip_thick-1])
        cube([probe_tip_len*2,0.8,probe_tip_thick]);
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
    // Commented out parts not used in V0.05
    //translate([20,0,0]) probe_holder();
    //probe_holder_rail();
    //translate([40,0,0]) probe_holder_rail();
    translate([0,-10,0]) probe_tip_arm();
    translate([31,-10,0]) probe_tip_arm();
    //translate([65,-10,0]) m3_thumbscrew_knob(7);
    translate([0,50,0]) probe_beam();
    translate([65,15,0]) probe_shuttle();
}
