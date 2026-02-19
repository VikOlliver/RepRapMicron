// maus_pika.scad - RepRapMicron Maus Print In-place Kinematic Axes
// (C) 2026 vik@diamondage.co.nz Released under the GPLV3 or later.
// It is a Very Good Idea(TM) to keep the dimensions in Metriccano (10mm) units.
// Printed on Prusa Mk4, 0.2mm layers, 20% infill, 2 v shells, 5 h shells

// If we can stagger the flexures on the outer (X) frame, we can make it smaller in X.
// Size constraints:
// Largely constrained by the attachment point for the Stage, located in the middle.
// If Y size is <120 it overhangs the bar at the top of the Y flexures and won't print.
// If X size <120 it overhangs the sides of the bar and interferes with the Y flexures.
//
// NOTE: Use Axis Drivers with mb_length_in_holes set to 2


include <../library/m3_parts.scad>
include <../library/metriccano.scad>
//include <../library/nema17lib.scad> Maybe use motors, even for direct drive, but  later...

version_string="PIKA V0.00";

flexure_thick=0.8;  // Width of a flexure beam, that's the very thin direction
flexure_width=5;      // Maximum desired flexing distance off centre
flexure_length=4;
flexure_height=1.2;   // Headroom given to a flexure

// These are used to create suspended or insignificant strings, for stabilizing printed
// parts or creating lines to stop 3D printer brim from invading.
stringer_height=0.4;
stringer_width=0.4;

beam_thick=5;       // Thickness of a vertical structural beam
beam_flexure_side=flexure_width+1;  // Width of a beam on the side contacting the flexure
flexure_clearance=1.5;      // Any flexing part must miss by this much
horizontal_beam_width=7;    // Width of a horizontal beam, used to join flexure pairs.
horizontal_beam_height=10;       // Height of the lower hollow square bracing beams etc.

structure_height=60;    // Maximum height of the total structure
frame_thick=5;              // Thickness of the notionally inflexible frame parts
// Dimensions of the box-like outer wall. If we can get x & y down to 120 that would be nice...
outer_wall_x_holes=12;
outer_wall_y_holes=12;
outer_wall_x=outer_wall_x_holes*metriccano_unit;       
outer_wall_y=outer_wall_y_holes*metriccano_unit;
box_wall=2;

// Sizings for the pair of flexures used everywhere
table_flexure_length=2*flexure_length+beam_thick;
table_flexure_pair_length=4*flexure_length+2*beam_thick+horizontal_beam_width;

// Dimensions of the lower square frame in the X flexures
outer_frame_x=outer_wall_x-2*box_wall-2*table_flexure_length+2*horizontal_beam_width;
outer_frame_y=outer_wall_y-2*box_wall-2*flexure_clearance;
outer_frame_stub=2*horizontal_beam_width+beam_flexure_side+2*flexure_clearance;
// Translation for start of the X Linkage
x_linkage_x_at=outer_wall_x-(outer_wall_x-outer_frame_x)/2-2*horizontal_beam_width;

// Dimensions of the inner wall
inner_wall_x=outer_wall_x-4*table_flexure_length-2*box_wall;
inner_wall_y=outer_frame_y-2*flexure_clearance-2*horizontal_beam_width;
inner_wall_at_x=(outer_wall_x-inner_wall_x)/2;
inner_wall_at_y=box_wall+2*flexure_clearance+horizontal_beam_width;

// Dimensions of the central box that suspends the Y axis
muckedup_box_x=0;

// Size of the square light well
light_well_size=metriccano_unit/2+0.5;
// This plate fits on top of the stage and has cutouts for magnets in it
magnet_x=10;
magnet_y=30;
magnet_z=3;
led_wire_rad=3.2/2;      // Gap for UV LED wires
led_strip_width=8;        // Dimensions of UV LED strip
led_strip_length=20;
led_strip_height=1;
st_base_thick=1;
stage_holes_x=6;        // Number of holes in the stage
stage_holes_y=4;
// Work out stage dimensions to make maths easier
stage_size_x=(stage_holes_x-1)*metriccano_unit;
stage_size_y=(stage_holes_y-1)*metriccano_unit;


// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}

// Flexure used to join beams on the integrated XY Table
module horizontal_flexure() {
    translate([0,0,flexure_height-flexure_thick]) cube([flexure_length,flexure_width,flexure_thick]);
}

// A pair of the flexures used on the integrated XY Table X axis.
// These are staggered about X=0 and tied together with a diagonal "string" to stop them
// from wobbling during printing

module staggered_flexure_pair() {
        translate([0,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
        translate([flexure_length,0,0]) cube([beam_thick,beam_flexure_side,structure_height]);
        translate([flexure_length+beam_thick,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5]) horizontal_flexure();
    translate([0,beam_flexure_side+horizontal_beam_width+3*flexure_clearance,0]) {
        // Ascending flexure and beam
        translate([-flexure_length,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
        translate([-flexure_length-beam_thick,0,0])
            cube([beam_thick,beam_flexure_side,structure_height]);
        // Top flexure on far end
        translate([-2*flexure_length-beam_thick,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5])
            horizontal_flexure();
    }
    // Stringer joining them together half way up
    hull() {
        translate([flexure_length+1,beam_flexure_side-1,structure_height/2])
            cube([stringer_width,stringer_width,stringer_height],center=true);
        translate([-flexure_length-1,beam_flexure_side+horizontal_beam_width+3*flexure_clearance+1,structure_height/2])
            cube([stringer_width,stringer_width,stringer_height],center=true);
    }
}

// A pair of the flexures used on the integrated XY Table Y axis
// These are tied delicately together half way up to reduce wobble during printing.
// This needs to be cut after printing.
module table_flexure_pair() {
    translate([0,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5]) horizontal_flexure();
    translate([flexure_length,0,0]) cube([beam_thick,beam_flexure_side,structure_height]);
    translate([flexure_length+beam_thick,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
    // Leave a gap for a central beam here
    // ...
    // Ascending flexure and beam
    translate([2*flexure_length+beam_thick+horizontal_beam_width,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
    translate([3*flexure_length+beam_thick+horizontal_beam_width,0,0])
        cube([beam_thick,beam_flexure_side,structure_height]);
    // Top flexure on far end
    translate([3*flexure_length+2*beam_thick+horizontal_beam_width,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5])
        horizontal_flexure();
    // Join the two with a couple of very thin beams.
    translate([table_flexure_pair_length/2,stringer_width/2,structure_height/2])
        cube([horizontal_beam_width+2*flexure_width,stringer_width,stringer_height],center=true);
    translate([table_flexure_pair_length/2,beam_flexure_side-stringer_width/2,structure_height/2])
        cube([horizontal_beam_width+2*flexure_width,stringer_width,stringer_height],center=true);
}

module x_flexure_pair() {
    translate([0,horizontal_beam_width+flexure_clearance,0]) staggered_flexure_pair();
    translate([outer_frame_x-2*horizontal_beam_width,horizontal_beam_width+flexure_clearance,0])
       scale([-1,1,1])  staggered_flexure_pair();
}

module y_flexure_pair() {
        translate([beam_flexure_side,0,0]) rotate([0,0,90]) table_flexure_pair();
        translate([beam_flexure_side,inner_wall_y-table_flexure_pair_length-2*box_wall,0]) rotate([0,0,90]) table_flexure_pair();
}

// Frame to stiffen outer wall and attach base to.
module frame_flange() union() {
    translate([-metriccano_unit/2,-metriccano_unit/2,0]) metriccano_strip(outer_wall_x_holes+2);
    translate([-metriccano_unit/2,-metriccano_unit/2,0]) rotate([0,0,90])
        metriccano_strip(outer_wall_y_holes+2);
    translate([-metriccano_unit/2,outer_wall_y+metriccano_unit/2,0]) metriccano_strip(outer_wall_x_holes+2);
    translate([outer_wall_x+metriccano_unit/2,-metriccano_unit/2,0]) rotate([0,0,90])
        metriccano_strip(outer_wall_y_holes+2);
}

// The outside box to which all the mounting hardware is attached, which has a hole
// through it for the X beam
module outside_box() union() {
    difference() {
        union() {
            cube([outer_wall_x,outer_wall_y,structure_height]);
            frame_flange();
        }
        // Hollow it out
        translate([box_wall,box_wall,-1])
            cube([outer_wall_x-2*box_wall,outer_wall_y-2*box_wall,structure_height*2]);
        // Chop out a hole for the X beam
        translate([outer_wall_x/2,(outer_wall_y-horizontal_beam_width)/2-flexure_clearance,-0.01])
            cube([outer_wall_x,horizontal_beam_width+2*flexure_clearance,horizontal_beam_height+flexure_clearance]);
        // And a hole for the Axis Driver attachment plate
        translate([outer_wall_x,outer_wall_y/2-metriccano_unit-flexure_clearance,-0.01])
            cube([100,(metriccano_unit+flexure_clearance)*2,metriccano_unit]);
    }
}

// The inside box containing the stage support
module inside_box() {
    difference() {
    cube([inner_wall_x,inner_wall_y,structure_height]);
    // Hollow it out
    translate([box_wall,box_wall,-1])
        cube([inner_wall_x-2*box_wall,inner_wall_y-2*box_wall,structure_height*2]);    
    }
}

// Mounting point for the stage, centred on (0,0)
module stage_mount() {
    difference() {
        // Central cubic form
        translate([0,0,metriccano_unit/2])
            cube([metriccano_unit*4,metriccano_unit*4,metriccano_unit],center=true);
        // Knock off lower corners to make it print when overhanging
        translate([0,metriccano_unit*2,0]) rotate([45,0,0])
            cube([metriccano_unit*4+1,metriccano_unit,metriccano_unit],center=true);
        translate([0,-metriccano_unit*2,0]) rotate([45,0,0])
            cube([metriccano_unit*4+1,metriccano_unit,metriccano_unit],center=true);
        // Screw and nut cavities
    for(i=[0:3]) {
            translate([metriccano_unit*(i-1.5),-metriccano_unit*1.5,0]) {
                metriccano_screw_hole();
                translate([0,0,metriccano_unit/2-2]) rotate([0,0,-90]) metriccano_nut_slot();
            }
            translate([metriccano_unit*(i-1.5),+metriccano_unit*1.5,0]) {
                metriccano_screw_hole();
                translate([0,0,metriccano_unit/2-2]) rotate([0,0,90]) metriccano_nut_slot();
            }
        }
    }
}

centre_platform_x=inner_wall_x-2*box_wall-2*flexure_clearance;
centre_platform_y=inner_wall_y-2*box_wall-2*table_flexure_pair_length;
// The pillar that rises up through the middle and holds the stage (or anchor bracket for it)
module centre_platform() {
        translate([outer_wall_x/2,outer_wall_y/2,0]) {
        // The bit the actual Stage will attach to
        translate([0,0,,structure_height])
                stage_mount();
        // 45 degree prism with the flat on top . Should be easy-ish to print suspended
        translate([0,0,structure_height]) hull() {
            cube([centre_platform_x,centre_platform_y,0.01],center=true);
            translate([0,0,-centre_platform_y*sqrt(2)/2]) cube([centre_platform_x,0.01,0.01],center=true);
        }
        // Centre pillar. We use beam_flexure_side as it is a known robust vertical support.
        translate([0,0,structure_height/2]) {
            cube([beam_flexure_side,centre_platform_y,structure_height],center=true);
            // Couple of end pillars
            translate([beam_flexure_side/2-centre_platform_x/2,0,0]) cube([beam_flexure_side,centre_platform_y-flexure_length,structure_height],center=true);
            translate([-beam_flexure_side/2+centre_platform_x/2,0,0]) cube([beam_flexure_side,centre_platform_y-flexure_length,structure_height],center=true);
        }
    }
}

// Bar that links the X axis framework to the Axis Driver
module x_linkage() translate([x_linkage_x_at,outer_wall_y/2,0]) {
    // Linkage bar
    translate([0,-horizontal_beam_width/2,0]) cube([outer_wall_x-x_linkage_x_at+metriccano_unit*3,horizontal_beam_width,horizontal_beam_height]);
    // Plate for fixing to X Axis Driver
    translate([outer_wall_x-x_linkage_x_at+metriccano_unit*3,-metriccano_unit/2,metriccano_unit*1.5]) {
        rotate([0,-90,0]) metriccano_plate(2,2,squared=true);
        // Fillet under fixing plate
        hull() {
            translate([-metriccano_unit/2,-metriccano_unit/2,-metriccano_unit/2])
                cube([metriccano_plate_height,metriccano_unit*2,1]);
            translate([-metriccano_unit/2,metriccano_unit/8,-metriccano_unit])
                cube([metriccano_plate_height,horizontal_beam_width,0.01]);
        }
    }
}

module pika_flexure_assembly() {
    outside_box();
    translate([box_wall,box_wall+flexure_clearance,0]) {
        // The X axis flexures onna square
        translate([table_flexure_length,0,0]) x_flexure_pair();
        translate([table_flexure_length,outer_frame_y,0]) 
            scale([1,-1,1]) x_flexure_pair();


        // Make the outer hollow square bracing beam with staggered edges
        translate([(outer_wall_x-outer_frame_x)/2-box_wall,0,0]) {
            difference() {
                // Square frame
                cube([outer_frame_x,outer_frame_y,horizontal_beam_height]);
                // Hollow it out
                translate([horizontal_beam_width,horizontal_beam_width,-1])
                    cube([outer_frame_x-2*horizontal_beam_width,outer_frame_y-2*horizontal_beam_width,horizontal_beam_height*2]);
                // Cut away two sides where we stagger it
                translate([-outer_frame_x/2,outer_frame_stub,-1])
                    cube([outer_frame_x*2,outer_frame_y-2*outer_frame_stub,horizontal_beam_height*2]);
            }
            // Kink back in towards the centre
            translate([horizontal_beam_width,outer_frame_stub-horizontal_beam_width,0])
                cube([horizontal_beam_width,outer_frame_y-2*outer_frame_stub+2*horizontal_beam_width,horizontal_beam_height]);
            translate([outer_frame_x-2*horizontal_beam_width,outer_frame_stub-horizontal_beam_width,0])
                cube([horizontal_beam_width,outer_frame_y-2*outer_frame_stub+2*horizontal_beam_width,horizontal_beam_height]);
        }
    }

    translate([inner_wall_at_x,inner_wall_at_y,0]) {
       inside_box();
        translate([box_wall+flexure_clearance,box_wall,0]) y_flexure_pair();
        translate([inner_wall_x-box_wall-flexure_clearance-beam_flexure_side,box_wall,0]) y_flexure_pair();
        // Two beams linking the pairs of flexures
        translate([box_wall+flexure_clearance,table_flexure_length+box_wall,0])
            cube([inner_wall_x-2*box_wall-2*flexure_clearance,horizontal_beam_width,horizontal_beam_height]);
        translate([box_wall+flexure_clearance,inner_wall_y-horizontal_beam_width-table_flexure_length-box_wall,0])
            cube([inner_wall_x-2*box_wall-2*flexure_clearance,horizontal_beam_width,horizontal_beam_height]);
        // Two beams linking the above linked paris, looking a bit like ][
        translate([box_wall+2*flexure_clearance+beam_flexure_side,table_flexure_length+box_wall,0])
            cube([horizontal_beam_width,inner_wall_y-2*box_wall-table_flexure_pair_length,horizontal_beam_height]);
        translate([inner_wall_x-box_wall-2*flexure_clearance-beam_flexure_side-horizontal_beam_width
        ,table_flexure_length+box_wall,0])
            cube([horizontal_beam_width,inner_wall_y-2*box_wall-table_flexure_pair_length,horizontal_beam_height]);
    }
    centre_platform();
    x_linkage();
    translate([outer_wall_x/2,0,structure_height-5]) rotate([90,0,0]) version_text();
}

// Tapered Axis Driver mount for near the driving end that should be printable without support
module generic_mount(driver_front_mount_width_mu=1) {
    union() {
        // Raise the top mounting point to the top of the axes structure
        translate([0,0,metriccano_unit*5]) hull() {
            // Form a Metriccano compliant beam with a 45 degree tapered underside, extending 2U
            cube([metriccano_unit*2,driver_front_mount_width_mu*metriccano_unit,metriccano_unit]);
            translate([0,0,-metriccano_unit*2]) cube([0.01,driver_front_mount_width_mu*metriccano_unit,0.01]);
        }
        // Create a rigid backing
        cube([metriccano_unit/2,driver_front_mount_width_mu*metriccano_unit,metriccano_unit*5]);
        // A base for anchoring the lower edge of the Axis Driver
        cube([metriccano_unit*2,driver_front_mount_width_mu*metriccano_unit,metriccano_unit*2]);    
    }
}

module driver_front_mount() {
    difference() {
        generic_mount();
        // Holes for Axis Driver attachment screws and nuts.
        translate([metriccano_unit/2,metriccano_unit/2,metriccano_unit*1.5])
            rotate([0,90,0]) metriccano_screw_hole(metriccano_unit*10);
        translate([metriccano_unit/2,metriccano_unit/2,metriccano_unit*5.5])
            rotate([0,90,0]) metriccano_screw_hole(metriccano_unit*10);
        // Nut slots
        // Top
        translate([metriccano_unit,metriccano_unit/2,metriccano_unit*5.5])
            rotate([0,-90,0])metriccano_nut_slot();
        // Bottom
        translate([metriccano_unit,metriccano_unit/2,metriccano_unit*1.5])
            rotate([0,-90,0])metriccano_nut_slot();
    }
}

// Axis Driver mount for attaching to the Motor Pillar
module driver_rear_mount(l=structure_height) {
    difference() {
        translate([0,0,l/2])
            cube([metriccano_unit,metriccano_unit,l],center=true);
        // Two screw holes
        translate([0,0,metriccano_unit*1.5])
            rotate([0,90,0]) metriccano_screw_hole();
        translate([0,0,metriccano_unit*5.5])
            rotate([0,90,0]) metriccano_screw_hole();
    }
}

// Mounting point for microscope supports
module microscope_mount() {
    difference() {
        // Body of the mounting block
        generic_mount(2);
        // Couple of screw holes going all the way through
        translate([metriccano_unit*1.5,metriccano_unit/2,0])
            metriccano_screw_hole(3*structure_height);
        translate([metriccano_unit*1.5,metriccano_unit*1.5,0])
            metriccano_screw_hole(3*structure_height);
        // Four nut slots, two on the top, two on the bottom
        translate([metriccano_unit*1.5,0,0]) {
            translate([0,metriccano_unit/2,structure_height-6]) metriccano_nut_slot();
            translate([0,metriccano_unit*1.5,structure_height-6]) metriccano_nut_slot();
            translate([0,metriccano_unit/2,12]) metriccano_nut_slot();
            translate([0,metriccano_unit*1.5,12]) metriccano_nut_slot();
        }
    }
}

//Z  Axis Driver mount for attaching to the front of the Motor Pillar
module z_driver_front_mount(l=120) {
    difference() {
        translate([0,0,l/2])
            cube([metriccano_unit,metriccano_unit,l],center=true);
        translate([0,0,l-metriccano_unit])
            metriccano_nut_slot();
        // Two screw holes, first one in the top
        translate([0,0,l-metriccano_unit/2])
            metriccano_screw_hole();
        // Second one in the side
        translate([0,0,l-metriccano_unit*2.5]) {
            rotate([90,0,0]) metriccano_screw_hole();
            translate([0,metriccano_unit/2,0]) rotate([90,0,0]) metriccano_nut_cavity_tapered(true);
        }
    }
}

//Z  Axis Driver mount for attaching to the rear of the Motor Pillar
module z_driver_rear_mount(l=90) {
    difference() {
        translate([0,0,l/2])
            cube([metriccano_unit,metriccano_unit,l],center=true);
        translate([0,0,l-metriccano_unit/2])
            rotate([90,0,-90]) metriccano_nut_slot();
        // Screw hole at the top
        translate([0,0,l-metriccano_unit/2])
            rotate([0,90,0]) metriccano_screw_hole();
    }
}

//NOTE: Z Tower is pre-positioned and rotated
module pika_z_tower() translate([outer_frame_x+1.5*metriccano_unit,metriccano_unit*12,0]) rotate([0,0,135]) union() {
    translate([-metriccano_unit*2,0,0]) scale([-1,1,1]) z_driver_front_mount();
    translate([metriccano_unit*2,0,0]) z_driver_front_mount();
    translate([-metriccano_unit,-metriccano_unit*2,0]) z_driver_rear_mount();
    translate([metriccano_unit,-metriccano_unit*2,0]) scale([-1,1,1]) z_driver_rear_mount();
    // Rigid box
    box_ht=75;
    translate([0,-metriccano_unit,box_ht/2]) difference() {
        cube([metriccano_unit*4,metriccano_unit*2.5,box_ht],center=true);
        translate([0,0,metriccano_unit/2])
            cube([metriccano_unit*3,metriccano_unit*2,box_ht],center=true);
    }
    // Lugs
    translate([-metriccano_unit*2.5,-1.5*metriccano_unit,0]) rotate([0,0,180]) metriccano_strip_flatend(1);
    translate([metriccano_unit*2.5,-1.5*metriccano_unit,0]) metriccano_strip_flatend(1);
}

module complete_pika() union() {
    pika_flexure_assembly();
    // X Axis Driver front mount
    translate([outer_wall_x,metriccano_unit*1,0]) driver_front_mount();
    // Y Axis Driver front mount
    translate([metriccano_unit*2,outer_wall_y,0]) rotate([0,0,90]) driver_front_mount();
    // X Axis Driver rear mount (closer to motor)
    translate([outer_wall_x-3*metriccano_unit,-metriccano_unit/2,0])
        driver_rear_mount();
    // Y Axis Driver rear mount (closer to motor)
    translate([-metriccano_unit/2,outer_wall_y-3*metriccano_unit,0])
        rotate([0,0,90]) driver_rear_mount();
    // Piece of bracing on the same side as the Y Axis Driver motor
    translate([-metriccano_unit/2,3.5*metriccano_unit,0])
        rotate([0,0,90]) driver_rear_mount();
    // Piece of bracing on the same side as the X Axis Driver flexures
    translate([outer_wall_x+metriccano_unit/2,outer_wall_y-3.5*metriccano_unit,0])
        rotate([0,0,90]) driver_rear_mount();
    // Microscope mount
    translate([metriccano_unit,0,0]) rotate([0,0,-90]) microscope_mount();
    // Tower to attach Z Axis Driver
    pika_z_tower();
    // A thin strip that will prevent a printed brim from going inside the flexures
    translate([outer_wall_x+metriccano_unit-0.3,outer_wall_y/2,0.2]) cube([stringer_width,50,stringer_height],center=true);
}

// The base prevents the bottoms of the flexures in the completed Pika assembly dragging on
// the ground. 
// It has a notch in it that allows the X Beam to move without catching on the base.
// It also has to support the Z Tower to reduce vibration. 
module pika_base() difference() {
    // Create a slice of Z Tower and attach it to the frame.
    union() {
        scale([1,1,metriccano_plate_height])
            intersection() {
                pika_z_tower();
                // Slice off a 1mm piece of the entire bottom of the Z Tower
                cube([999,999,2],center=true);
            }
         frame_flange();
    }
    // Chop out a hole for the X beam
    translate([outer_wall_x/2,(outer_wall_y-horizontal_beam_width)/2-flexure_clearance,metriccano_plate_height-1])
        cube([outer_wall_x,horizontal_beam_width+2*flexure_clearance,2]);
}

show_dummy_drivers=true;
// Dummy Axis Drivers for model positioning (there is a 2mm offset of Metriccano holes in the
// model. My bad. Doesn't matter when you're actually printing one but too lazy to fix today.
module axis_driver() {
    if (show_dummy_drivers) {
        import("frame_trio.stl");
        translate([metriccano_unit*9.3,0,-metriccano_unit*4.5]) rotate([0,0,180]) import("motor_pillar_pika.stl");
    }
}

if (show_dummy_drivers) {
    // Y Driver
    %translate([metriccano_unit*4.8,outer_wall_y+metriccano_unit*2,metriccano_unit*3.5]) rotate([-90,180,0]) axis_driver();
    // X Driver
    %translate([outer_wall_x+metriccano_unit*2,metriccano_unit*(floor(outer_wall_y_holes/2)-1.2),metriccano_unit*3.5]) rotate([-90,0,-90]) axis_driver();
    // Z Driver
    %translate([outer_wall_x/2+3*metriccano_unit,outer_wall_y/2+3*metriccano_unit,12*metriccano_unit]) rotate([0,0,45]) axis_driver();
}

//translate([0,0,metriccano_unit/2]) 
complete_pika();
//pika_base();
