// pika_z_flexures.scad - RepRapMicron motion stage
// (c)2026 vik@diamondage.co.nz, released under the terms of the GPL V3 or later
// Z Axis Driver flexures, a pair. These stabilize the Z Axis so that it can only move
// up and down.

include <../library/metriccano.scad>
include <pika_version.scad>

// Z Flexures have their own thicknesses and so forth because their rigidity requirements are different.
flexure_width=0.8;  // Width of a flexure beam, that's the very thin direction
flexure_max=8+flexure_width;      // Maximum desired flexing distance off centre
flexure_clearance=1.5;      // Any flexing part must miss by this much

frame_thick=5;              // Thickness of the notionally inflexible frame parts

// Flexure to rigidly constrain the Z axis to vertical motion only.
// X=0,Y=0 centred on the free end of the anchor hole on the end of the Axis Driver
// Turned on its side for zero support printing.
zflex_beam_thick=frame_thick;
zflex_inner_beam_length=metriccano_unit+2*(flexure_max+flexure_width);
zflex_outer_beam_length=zflex_inner_beam_length+flexure_max*2+flexure_width;
zflex_flexure_length=40;
z_flexure_height=9.2;  // Make the Z flexures wider for stability

// A generic flexure, origin [0,0,0].
// Experience shows only the last bit of flexure needs to actually flex, the rest
// allows excessive torsion so apply a limit and thicken the rest.
// Later this will acquire tapering, etc.
flex_limit_len=10;
module generic_flexure(length,ht=z_flexure_height) {
    cube([flexure_width,length,ht]);
    if (length>flex_limit_len*2) {
        // Put in an elongated stiff bit
        hull() {
            translate([flexure_width/2,flex_limit_len,ht/2]) 
                rotate([0,0,45]) cube([flexure_width*2,flexure_width*2,ht],center=true);
            translate([flexure_width/2,length-flex_limit_len,ht/2]) 
                rotate([0,0,45]) cube([flexure_width*2,flexure_width*2,ht],center=true);
        }
    }
}

// If flipped, we flip the version text
module zflex_outer_beam_frame(flipped=1){
    // Outer beam, attached to free end of Axis Driver
    translate([-metriccano_unit/2,-zflex_outer_beam_length/2,0])
        cube([zflex_beam_thick,zflex_outer_beam_length,z_flexure_height]);
    // Inner flexures
    translate([0,-zflex_outer_beam_length/2+flexure_width,0]) rotate([0,0,-90]) generic_flexure(zflex_flexure_length,z_flexure_height);
    translate([0,zflex_outer_beam_length/2,0]) rotate([0,0,-90]) generic_flexure(zflex_flexure_length,z_flexure_height);
    // Outer beam, attached to inner flexures.
    // Needs to be translated out to allow clearance for inner beam
    translate([zflex_flexure_length,0,0]) {
        translate([flexure_clearance+zflex_beam_thick,-zflex_outer_beam_length/2,0]) {
            cube([zflex_beam_thick,zflex_outer_beam_length,z_flexure_height]);
            // Version data
            translate([zflex_beam_thick,zflex_outer_beam_length/2,z_flexure_height/2])
                rotate([0,90,0]) rotate([0,0,90]) scale([flipped,1,1]) version_text();
        }
        // Support blocks for outer inner_flexures
        translate([0,-zflex_outer_beam_length/2,0])
            cube([flexure_clearance+zflex_beam_thick,flexure_max/2,z_flexure_height]);
        translate([0,zflex_outer_beam_length/2-flexure_max/2,0])
            cube([flexure_clearance+zflex_beam_thick,flexure_max/2,z_flexure_height]);
    }
}


// Inner beam and flexures for Z flexure
module zflex_inner_beam_frame() {
    // Beam that attaches to Axis Driver frame
    translate([-metriccano_unit/2,-zflex_inner_beam_length/2,0])
        cube([zflex_beam_thick,zflex_inner_beam_length,z_flexure_height]);
    // Inner flexures
    translate([0,-zflex_inner_beam_length/2+flexure_width,0]) rotate([0,0,-90]) generic_flexure(zflex_flexure_length,z_flexure_height);
    translate([0,zflex_inner_beam_length/2,0]) rotate([0,0,-90]) generic_flexure(zflex_flexure_length,z_flexure_height);
}

// Assembled Z flexure
// Flipped = -1 mirrors the assembly and keeps version text legible.
module z_flexure(flipped=1) union()  scale([1,flipped,1]) {
    // Attachment under plate of Axis Driver
    translate([-metriccano_unit*2,0,0]) {
        translate([zflex_beam_thick,metriccano_plate_height,metriccano_unit/2+flexure_clearance+z_flexure_height]) rotate([90,0,0]) metriccano_plate(2,2,squared=true);
        // Mounting plate link
        cube([metriccano_unit*2,metriccano_plate_height,z_flexure_height+flexure_clearance]);
    }

    // Outer flexures
    zflex_outer_beam_frame(flipped);
    // Inner flexures
    translate([flexure_clearance+zflex_beam_thick,0,0]) zflex_inner_beam_frame();
    // Attachment point to side of Axis Driver. Fill with holes
    difference() {
        translate([zflex_beam_thick+flexure_clearance,-metriccano_unit/2]) cube([zflex_flexure_length-flexure_clearance,metriccano_unit,z_flexure_height+flexure_clearance]);
        for (i=[1:floor(zflex_flexure_length/metriccano_unit)])
            translate([i*metriccano_unit-zflex_beam_thick,0,metriccano_unit/2]) metriccano_screw_hole();
    }
}

// Z Axis parts
z_flexure();
translate([0,60,0]) z_flexure(-1);
