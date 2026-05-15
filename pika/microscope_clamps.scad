
include <../library/m3_parts.scad>
include <../library/metriccano.scad>
include <./pika_version.scad>

boss_square=15;         // Beefy square section
boss_w=boss_square;
boss_h=14;                  // There was a problem with screws, the boss camps need to be slightly smaller vertically.
clamping_pole_arm_length=55;
pole_clip_width=3;
pole_stand_rad=16/2;             // 16mm pole
pole_stand_arm_length=7;     // Length of stand arm in metriccano units.


// A clamp of specified internal radius and wall thickness
module bolted_clamp(int_rad,thick) {
    bolt_shift=boss_square/2+int_rad;
    difference() {
        union() {
            // Clamp round body
            cylinder(h=boss_h,r=int_rad+thick,$fn=64);
            // Clamp clip
            translate([-bolt_shift,0,boss_h/2]) cube([boss_w,boss_w,boss_h],center=true);
        }
        // Poke hole in ring
        cylinder(h=boss_square*3,r=int_rad,center=true,$fn=64);
        // Split the clip
        translate([-bolt_shift,0,0]) cube([boss_square+2*int_rad,5,boss_square+2*int_rad],center=true);
        // Shove a screw hole through the clip
        translate([-bolt_shift,0,boss_square/2]) rotate([90,0,0]) m3_screw_hole(2*boss_square);
        // Put a captive nut on one side
        translate([-bolt_shift,-boss_square/2,boss_square/2]) rotate([-90,0,0]) m3_nut_cavity_tapered(captive=true);
    }
}

// Mounting to hold a USB microscope on the same pole as above.
// Should probably make one with the slot horizontal at some point...
module clamping_pole_arm() difference() {
    // Body of stand with a metriccano slot sticking out
    union () {
        // The clamp body
        bolted_clamp(pole_stand_rad,pole_clip_width);
        // The arm body
        translate([clamping_pole_arm_length/2,0,boss_h/2])
            cube([clamping_pole_arm_length,boss_w,boss_h],center=true);
        // Rounded arm end
        translate([clamping_pole_arm_length,0,0]) cylinder(h=boss_h,r=boss_w/2,$fn=64);
        // Version stamp
        translate([pole_stand_rad+clamping_pole_arm_length/2,-boss_w/2,boss_h/2])
            rotate([90,0,0]) version_text();
    }
    // Hole in the middle for post
    cylinder(h=boss_square*3,r=pole_stand_rad,center=true,$fn=64);
    // Slot to run an M3 bolt in, holding the hinge
    hull() {
        translate([boss_square+pole_clip_width,0,0]) m3_screw_hole(boss_square*3);
        translate([clamping_pole_arm_length,0,0]) m3_screw_hole(boss_square*3);
    }
}

pole_arm_hinge_rad=boss_h/2;
pole_arm_hinge_height=12;   // Main height restriction here is the need to hide an M3 nut in the base.
pole_clearance=0.3;
// A hinge that can run up and down the clamping pole arm on an M3 screw. It's meant to rotate.
// Let's base it on Metriccano units for funsies
module clamping_pole_hinge() {
    // Base for hinge. Whack out curvy bits for the top half of the hinge to swing in
    difference() {
        union() {
            // Verical structure of pivot
            cylinder(h=pole_arm_hinge_height+metriccano_unit/4,r=pole_arm_hinge_rad,$fn=64);
            // Rounded flange on top of pivot
            translate([0,0,pole_arm_hinge_height+metriccano_unit/2]) rotate([0,90,0]) 
                cylinder(h=metriccano_unit/2-pole_clearance,r=pole_arm_hinge_rad,center=true,$fn=64);
        }
        // Curvy sockets
        translate([metriccano_unit/4-pole_clearance/2,0,pole_arm_hinge_height+metriccano_unit/2]) rotate([0,90,0])
            cylinder(h=pole_arm_hinge_rad,r=pole_arm_hinge_rad+pole_clearance,$fn=64);
        translate([-metriccano_unit/4+pole_clearance/2,0,pole_arm_hinge_height+metriccano_unit/2]) rotate([0,-90,0])
            cylinder(h=pole_arm_hinge_rad,r=pole_arm_hinge_rad+pole_clearance,$fn=64);
        // M3 hole through the middle
        translate([metriccano_unit,0,pole_arm_hinge_height+metriccano_unit/2]) rotate([0,90,0])
            m3_screw_cavity(metriccano_unit*2);
        // M3 hole up the middle
        m3_screw_hole(pole_arm_hinge_height);
        // Slot for captive nut
        translate([0,0,3]) rotate([0,0,-90]) m3_nut_slot();
    }
}

clamp_shaft_len=40;
// A clamp to grab the USB microscope at the narrow end. Takes the diameter of the microscope
module microscope_clamp(mdia=32) {
    // You can add clearance to mdia here if your printer needs it.
    mrad=(mdia)/2;    // Use reduced radius to ensure tight grip
    difference() {
        // Build a magnifying glass-like holder for the microscope
        union() {
            bolted_clamp(mrad,pole_clip_width);
            // Octagonal easy-print shaft
            translate([mrad+clamp_shaft_len/2,0,pole_arm_hinge_rad]) intersection() {
                cube([clamp_shaft_len,pole_arm_hinge_rad*2,pole_arm_hinge_rad*2],center=true);
                rotate([45,0,0]) cube([clamp_shaft_len,pole_arm_hinge_rad*2,pole_arm_hinge_rad*2],center=true);
            }
            // Version stamp
            translate([mrad+clamp_shaft_len/2,0,pole_arm_hinge_rad*2]) version_text();
            // Dimensions
           translate([mrad+10,-pole_arm_hinge_rad,pole_arm_hinge_rad]) rotate([90,0,0]) linear_extrude(0.2)
                text(str(mdia,"mm dia."), size = 3, halign = "left", valign = "center", $fn = 16);
        }
        // Poke a screw hole and nut slot in the handle end.
        translate([clamp_shaft_len+mrad-8,0,pole_arm_hinge_rad]) rotate([0,90,0])  {
            m3_nut_slot();
            m3_screw_hole(20);
       }
    }
}

translate([65,15,0]) rotate([0,0,180]) clamping_pole_arm();
for (i=[0:1]) translate ([0,i*-20,0]) {
    translate([20,60,0]) m3_thumbscrew_knob(7);
    translate([35,65,0]) m3_thumbscrew_knob(7);
    translate([50,60,0]) m3_thumbscrew_knob(7);
    translate([65,65,0]) m3_thumbscrew_knob(7);
    translate([80,60,0]) m3_thumbscrew_knob(7);
}
translate([0,20,0]) {
    translate([125,67,0]) clamping_pole_hinge();
    translate([125,67,0]) microscope_clamp(33);
    translate([120,34,0]) clamping_pole_arm();
    translate([155,4,0])  clamping_pole_hinge();
    translate([155,4,0]) rotate([0,0,180]) microscope_clamp(36);
}
