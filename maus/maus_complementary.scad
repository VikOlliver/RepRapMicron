// maus_complementary.scad - RepRapMicron Maus vertical complimentary flexure stage
// (C) 2025 vik@diamondage.co.nz Released under the GPLV3 or later.
// Notes:
// Requires 3 standard Maus axis drivers and probe holder parts
// Base should be secured to 10mm pitch perforated sheet, 13 x 11 holes
//  avaliable as metriccano_baseboard.svg for lasercutting
// It is a Very Good Idea(TM) to keep the width in Metriccano (10mm) units.
// Printed on Prusa Mk4, 0.2mm layers, 20% infill, 2 v shells, 5 h shells

include <../library/m3_parts.scad>
include <../library/metriccano.scad>
include <../library/nema17lib.scad>

version_string="MAUSC V0.03";

// TODO
// Test cross-bracing of flexures.

flexure_width=0.8;  // Width of a flexure beam, that's the very thin direction
flexure_max=8+flexure_width;      // Maximum desired flexing distance off centre
flexure_height=6;

structure_height=70;    // Maximum height of the total structure
frame_thick=5;              // Thickness of the notionally inflexible frame parts
flexure_clearance=3;    // Give this much clearance on fixed flexure parts that must miss each other
edge_clearance=1.5;       // For the edges of the table mount to clear the frame. Displace mounting holes by this much.
x_axis_width=100;          // Width of the outer frame of the flexure structure
y_axis_width=80-edge_clearance;          // Width of the table frame of the flexure structure


// Length of the outer frame flexures
outer_frame_flexure_len=structure_height-frame_thick*3-flexure_clearance;
inner_frame_flexure_len=outer_frame_flexure_len-frame_thick-flexure_clearance;
// The outer frame flexures are spaced this far in from the frame edge
outer_mf_offset=frame_thick+flexure_max/2+flexure_width/2;
// Ditto inner flexures of the outer frame
inner_mf_offset=outer_mf_offset+flexure_max+flexure_width/2;

// The table frame is the flexure unit attached to the outer frame
table_frame_height=outer_frame_flexure_len+frame_thick;
outer_table_flexure_len=table_frame_height-frame_thick-flexure_clearance;
inner_table_flexure_len=outer_table_flexure_len-frame_thick-flexure_clearance;
// The outer table frame flexures are spaced this far in from the frame edge
outer_tf_offset=max(frame_thick+flexure_max/2+flexure_width/2+edge_clearance,metriccano_unit);
// Ditto inner flexures of the table frame
inner_tf_offset=outer_tf_offset+flexure_max+flexure_width/2;
// Size of the square light well
light_well_size=metriccano_unit/2+0.5;
// This plate fits on top of the stage and has cutouts for magnets in it
/* Original magnet
magnet_x=9.6;
magnet_y=29.5;
magnet_z=2; */
// Alternative magnet
magnet_x=10;
magnet_y=30;
magnet_z=3;
led_wire_rad=3.2/2;      // Gap for UV LED wires
led_strip_width=8;        // Dimensions of UV LED strip
led_strip_length=20;
led_strip_height=1;
st_base_thick=1;
st_plate_height=st_base_thick+magnet_z+m3_screw_head_height+0.2;  // Hide screw heads under the magnet.
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

// A generic flexure, origin [0,0,0].
// Experience shows only the last bit of flexure needs to actually flex, the rest
// allows excessive torsion so apply a limit and thicken the rest.
// Later this will acquire tapering, etc.
flex_limit_len=10;
module generic_flexure(length) {
    cube([flexure_width,length,flexure_height]);
    if (length>flex_limit_len*2) {
        // Put in an elongated stiff bit
        hull() {
            translate([flexure_width/2,flex_limit_len,flexure_height/2]) 
                rotate([0,0,45]) cube([flexure_width*2,flexure_width*2,flexure_height],center=true);
            translate([flexure_width/2,length-flex_limit_len,flexure_height/2]) 
                rotate([0,0,45]) cube([flexure_width*2,flexure_width*2,flexure_height],center=true);
        }
    }
}

// This is the outer frame. It attaches to the base
module outer_frame_unit() {
    // Create the outer frame
    difference() {
        cube([x_axis_width,structure_height,flexure_height+edge_clearance]);
        translate([frame_thick,frame_thick,-1]) cube([x_axis_width-2*frame_thick,structure_height-2*frame_thick,flexure_height*2]);
        // Chop edge clearance off the top edge of the frame
        translate([metriccano_unit/2,-1,flexure_height]) cube([x_axis_width-metriccano_unit,frame_thick+2,edge_clearance+1]);
    }

    // Version stamp
    translate([x_axis_width/2,0,flexure_height/2]) rotate([90,0,0])
        version_text();

    // Put metriccano strips on the frame for final assembly
    mf_assy_holes=floor(structure_height/metriccano_unit);
    // Sides
    translate([frame_thick,metriccano_unit/2,metriccano_unit+edge_clearance]) rotate([-90,0,90])
        metriccano_strip(mf_assy_holes,squared=true);
    translate([x_axis_width-frame_thick,metriccano_unit/2,metriccano_unit+edge_clearance]) rotate([90,0,90])
        metriccano_strip(mf_assy_holes,squared=true);
    // Bottom
    translate([metriccano_unit/2,structure_height,metriccano_unit+edge_clearance]) rotate([90,0,0])
        metriccano_strip(floor(x_axis_width/metriccano_unit),squared=true);
    // The two outermost flexures on the main frame.
    translate([outer_mf_offset,frame_thick,0])
        generic_flexure(outer_frame_flexure_len);
    translate([x_axis_width-outer_mf_offset-flexure_width,frame_thick,0])
        generic_flexure(outer_frame_flexure_len);
    // Cross beam that joins the two outermost flexures on the main frame.
    translate([outer_mf_offset,outer_frame_flexure_len+frame_thick,0])
        cube([x_axis_width-2*outer_mf_offset,frame_thick,flexure_height]);
    // The two innermost flexures on the main frame
    translate([inner_mf_offset,frame_thick*2+flexure_clearance,0])
        generic_flexure(inner_frame_flexure_len);
    translate([x_axis_width-inner_mf_offset-flexure_width,frame_thick*2+flexure_clearance,0])
        generic_flexure(inner_frame_flexure_len);
    translate([inner_mf_offset,frame_thick+flexure_clearance,0]) {
            // Metriccano table mount. Reduced in height to match frame width
            // so it doesn't interfere with flexure movement.
            // Maths to put right number of holes in Metriccano plate
            mf_mount_holes=floor((x_axis_width-2*inner_mf_offset)/metriccano_unit+0.75);
            // Figure out where to centre the mounting strip
            mf_mount_centre=(x_axis_width-2*inner_mf_offset)/2-(metriccano_unit*(mf_mount_holes-1))/2;
            translate([mf_mount_centre,0,metriccano_unit+edge_clearance])
                rotate([-90,0,0]) 
                    scale([1,1,frame_thick/metriccano_unit*2])
                        metriccano_strip(mf_mount_holes,squared=true);
            cube([x_axis_width-2*inner_mf_offset,frame_thick,flexure_height+edge_clearance]);
    }

}
    
// This is a table flexure assembly. It attaches to the outer frame and supports the XY Table
module table_frame_unit() {
    // The main suspension beam with two-point Metriccano mount holes
    difference() {
        union() {
            cube([y_axis_width,frame_thick,flexure_height]);
            // "Wings" for mount holes
            cube([metriccano_unit,frame_thick,metriccano_unit*2-flexure_height/2+edge_clearance]);
            translate([y_axis_width-metriccano_unit,0,0]) cube([metriccano_unit,frame_thick,metriccano_unit*2-flexure_height/2+edge_clearance]);
        }
        translate([metriccano_unit/2,0,flexure_height/2+edge_clearance]) rotate([90,0,0]) metriccano_screw_hole();
        translate([y_axis_width-metriccano_unit/2,0,flexure_height/2+edge_clearance]) rotate([90,0,0]) metriccano_screw_hole();
        translate([metriccano_unit/2,0,flexure_height/2+metriccano_unit+edge_clearance]) rotate([90,0,0]) metriccano_screw_hole();
        translate([y_axis_width-metriccano_unit/2,0,flexure_height/2+metriccano_unit+edge_clearance]) rotate([90,0,0]) metriccano_screw_hole();
    }
    // The two outermost flexures on the table frame.
    translate([outer_tf_offset,frame_thick,0])
        generic_flexure(outer_table_flexure_len);
    translate([y_axis_width-outer_tf_offset-flexure_width,frame_thick,0])
        generic_flexure(outer_table_flexure_len);
    // Cross beam that joins the two outermost flexures on the main frame.
    translate([outer_tf_offset,outer_table_flexure_len+frame_thick,0])
        cube([y_axis_width-2*outer_tf_offset,frame_thick,flexure_height]);
    // The two innermost flexures on the main frame
    translate([inner_tf_offset,frame_thick*2+flexure_clearance,0])
        generic_flexure(inner_table_flexure_len);
    translate([y_axis_width-inner_tf_offset-flexure_width,frame_thick*2+flexure_clearance,0])
        generic_flexure(inner_table_flexure_len);
    // This is the beam that the table attaches to
    translate([inner_tf_offset,frame_thick+flexure_clearance,0]) {
        // Metriccano table mount. Reduced in height to match frame width
        // so it doesn't interfere with flexure movement. Ideally lines up
        // with all the other mounting holes...
        // Maths to put right number of holes in Metriccano strip
        tf_mount_holes=floor((y_axis_width-2*inner_tf_offset)/metriccano_unit+0.75);
        // Figure out where to centre the mounting strip
        tf_mount_centre=(y_axis_width-2*inner_tf_offset)/2-(metriccano_unit*(tf_mount_holes-1))/2;
        translate([tf_mount_centre,0,metriccano_unit+flexure_height/2+edge_clearance])
            rotate([-90,0,0]) 
                scale([1,1,frame_thick/metriccano_unit*2]) difference() {
                    // Stick a couple of captive nut holes in the mounting strip or assembly is *hard*
                    metriccano_strip(tf_mount_holes,squared=true);
                    translate([metriccano_unit,0,metriccano_unit/2])
                        rotate([180,0,0]) metriccano_nut_cavity_tapered(captive=true);
                    translate([metriccano_unit*2,0,metriccano_unit/2])
                        rotate([180,0,0]) metriccano_nut_cavity_tapered(captive=true);
                }
        cube([y_axis_width-2*inner_tf_offset,frame_thick,flexure_height*1.5+edge_clearance]);
    }
}

// The dimensions of the well that lets UV light up from under the stage
module light_well() {
    translate([stage_size_x/2,stage_size_y/2,0])
        hull() {
            translate([light_well_size,light_well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([-light_well_size,light_well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([light_well_size,-light_well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([-light_well_size,-light_well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
        }
}
// Plain stage, no linkages, flexures or linkage tunnels
module plain_stage() difference() {
    union() {
        difference() {
            // Join up the flexure blocks and the mounting plate
            union() {

                //translate([-metriccano_unit,metriccano_unit*0.75,0]) 
                metriccano_plate(stage_holes_x,stage_holes_y);
                // Version text
                translate([-metriccano_unit*0.5,stage_size_y/2,metriccano_unit/4]) rotate([0,-90,0]) rotate([0,0,90])
                    version_text();
            }
            // Nut sockets in the corners
            translate([0,0,metriccano_unit/2-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([metriccano_unit,0,metriccano_unit/2-m3_nut_height+0.001])
                m3_nut_cavity();
            // This one is a hole for the ground probe post screw
            translate([4*metriccano_unit,0,metriccano_unit/2-m3_screw_head_height])
                m3_screw_cavity();
            translate([5*metriccano_unit,0,metriccano_unit/2-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([0,metriccano_unit*3,metriccano_unit/2-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([metriccano_unit,metriccano_unit*3,metriccano_unit/2-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([4*metriccano_unit,metriccano_unit*3,metriccano_unit/2-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([5*metriccano_unit,metriccano_unit*3,metriccano_unit/2-m3_nut_height+0.001])
                m3_nut_cavity();
        }
    }
    // Cut light well (a Metriccano unit-ish hole with rounded corners)
    light_well();
}

// The shape of the magnet cavity in the slide top. Has tiny protrusions in the ends that can be
// mashed to grip the magnet firmly
module magnet_slot() {
    magnet_nub_width=0.8;
    difference() {
        cube([magnet_x,magnet_y,magnet_z+0.01],center=true);
        translate([0,magnet_y/2,0]) rotate([0,0,45])
            cube([magnet_nub_width,magnet_nub_width,magnet_z+0.01],center=true);
        translate([0,-magnet_y/2,0]) rotate([0,0,45])
            cube([magnet_nub_width,magnet_nub_width,magnet_z+0.01],center=true);
    }
}

// The top section of the stage. Has recesses for grounding pillar and slide moutn magnets
module stage_top() {
    difference() {
        // Scale the plate to be the same thickness as a magnet plus a screw head
        union() {
            scale([1,1,(st_plate_height)/metriccano_unit*2]) metriccano_plate(stage_holes_x,stage_holes_y);
            // Version stamp
            translate([stage_size_x+metriccano_unit*0.5,stage_size_y/2,metriccano_unit/4]) rotate([0,90,0]) rotate([0,0,90])
                scale(0.8) version_text();
        }
        // Chop out the light well
        light_well();
        // Holes for a screw head underneath to take grounding post
        translate([metriccano_unit,0,m3_screw_head_height+0.2]) rotate([180,0,0]) m3_screw_cavity();
        translate([stage_size_x-metriccano_unit,stage_size_y,m3_screw_head_height+0.2]) rotate([180,0,0]) m3_screw_cavity();
        // Holes for screw heads
        translate([0,(stage_size_y+metriccano_unit)/2,st_base_thick]) m3_screw_cavity();
        translate([0,(stage_size_y-metriccano_unit)/2,st_base_thick]) m3_screw_cavity();
        translate([stage_size_x,(stage_size_y+metriccano_unit)/2,st_base_thick]) m3_screw_cavity();
        translate([stage_size_x,(stage_size_y-metriccano_unit)/2,st_base_thick]) m3_screw_cavity();
        // Chop out magnet slots. Insetting from ends by 3mm allows the touchplate on a slide to get to the centre of the stage.
        translate([3,metriccano_unit*1.5,st_plate_height-magnet_z/2]) magnet_slot();
        translate([metriccano_unit*5-3,metriccano_unit*1.5,st_plate_height-magnet_z/2]) magnet_slot();
        // Hollow out a cavity for the UV LED under the light well
        translate([stage_size_x/2,stage_size_y/2,0]) cube([led_strip_length,led_strip_width,led_strip_height*2],center=true);
        // Cavity for LED wires
        translate([0,stage_size_y/2,led_wire_rad*0.35]) rotate([0,90,0]) rotate([0,0,180/8]) cylinder(h=metriccano_unit*6,r=led_wire_rad,$fn=8,center=true);
        // Cavity for solder joints onto UV LED strip, bending wires to terminals, etc.
        solder_cavity_len=7;
        solder_cavity_height=2.6;
        translate([(stage_size_x-light_well_size)/2-solder_cavity_len,stage_size_y/2,solder_cavity_height/2-0.01])
            cube([solder_cavity_len,led_strip_width,solder_cavity_height],center=true);
    }
}

// A stage with an X axis flexure (length fl) stuck out the side
module flexured_stage(fl) {
    plain_stage();
    // Shift the flexure  and anchor en masse
    translate([metriccano_unit*2.5,-metriccano_unit/2,0]) {
        // Very thin flexure joining anchor and stage
        translate([-0.4,metriccano_unit*4,0]) cube([0.8,fl,metriccano_plate_height]);
        // Stress reliefs
        translate([0,metriccano_unit*4,metriccano_plate_height/2])
            rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
        translate([0,metriccano_unit*4+fl,metriccano_plate_height/2])
            rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
            // Legend
        translate([-5,metriccano_unit*5+fl,0])
            difference() {
                cube([10,8,metriccano_unit/2]);
                translate([5,4,-0.3]) rotate([0,0,-90]) linear_extrude(0.6)
                    text("X", size = 4, halign = "center", valign = "center", $fn = 16);
                }
        // Anchor point for actuator
        translate([-metriccano_unit*0.5,metriccano_unit*4.5+fl,0]) metriccano_slot_strip(1.5);
    }
}

// A bracing beam for joining frame halves together
bracing_holes=floor(y_axis_width/metriccano_unit+0.5);
module bracing_beam() union() {
    metriccano_strip(bracing_holes);
    rotate([0,0,90]) metriccano_strip(2);
    translate([(bracing_holes-1)*metriccano_unit,0,0]) rotate([0,0,90]) metriccano_strip(2);
}

nema_brace_x=4;
nema_brace_y=5;
module brace_with_nema17() {
    // Create a metriccano plate with NEMA17-shaped holes in it
    difference() {
        metriccano_plate(nema_brace_x,nema_brace_y);
        // Hole for NEMA collar and mounting holes
        translate([metriccano_unit*1.5,metriccano_unit*1.5,0]) {
            // Collar hole
            cylinder(h=metriccano_unit*3,r=nema17_collar_rad,center=true);
            // Screw holes
            translate([nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
            translate([-nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
            translate([nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
            translate([-nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
        }
    }
    // A rigid cross-beam for mounting to the side of the table assembly at the far Y end
    translate([metriccano_unit*(bracing_holes-3),metriccano_unit*(nema_brace_y-1),0]) rotate([0,0,180])
        union() {
            // Basic beam
            metriccano_l_beam(bracing_holes);
            // Put two vertically spaced holes on each end of the beam
            translate([0,-metriccano_unit/2,metriccano_unit]) rotate([90,0,0]) rotate([0,0,90]) metriccano_strip(2);
            translate([metriccano_unit*(bracing_holes-1),-metriccano_unit/2,metriccano_unit]) rotate([90,0,0]) rotate([0,0,90]) metriccano_strip(2);
        }
}

// Heavy square double bracket to hang Y axis on.
module y_axis_mount() union() {
    // U-Shaped bracket
    translate([metriccano_unit*7,0,0]) metriccano_square_strip(2);
    translate([metriccano_unit*7,metriccano_unit*4,0]) metriccano_square_strip(2);
    rotate([0,0,90]) metriccano_square_strip(5);
    // These bits are thinner to allow space for the Y driver beam's movement
    translate([metriccano_unit,metriccano_unit*4,0]) metriccano_strip(6,squared=true);
    translate([metriccano_unit,0,0]) metriccano_strip(6,squared=true);
}

// Single unit knobs for x_axis_mount that have retained nuts, thickened to increase beam strength
module x_mount_nutted() {
    rotate([0,-90,0])
        difference() {
            union() {
                // Create a 2-unit square strip with a solid end
                metriccano_square_strip(1);
                translate([metriccano_unit/2,-metriccano_unit/2,0]) cube(metriccano_unit);
            }
            translate([metriccano_unit,0,metriccano_unit]) rotate([180,0,0]) {
                metriccano_nut_cavity_tapered(captive=true);
                metriccano_screw_hole(metriccano_unit*3);
            }
        }
}
// Heavy square double bracket to hang X axis on. Needs a bit more displacement on the X axis for the driver flexure
module x_axis_mount() difference(){
    union() {
        // U-shaped bracket
        metriccano_square_strip(9);
        translate([0,metriccano_unit*4,0]) metriccano_square_strip(9);
        rotate([0,0,90]) metriccano_square_strip(5);
        translate([metriccano_unit*8,metriccano_unit,0]) rotate([0,0,90]) metriccano_square_strip(3);
        // Single unit knobs on the top of the U arms to give more stable mount points
        translate([metriccano_unit*9.5,0,metriccano_unit/2]) x_mount_nutted();
        translate([metriccano_unit*9.5,metriccano_unit*4,metriccano_unit/2]) x_mount_nutted();
        // Solidify the corners near captive nuts
        translate([metriccano_unit/2,-metriccano_unit/2,0]) cube([metriccano_unit/4,metriccano_unit,metriccano_unit]);
        translate([metriccano_unit/2,metriccano_unit*3.5,0]) cube([metriccano_unit/4,metriccano_unit,metriccano_unit]);
    }
    // Captive nuts to hold microscope stand brackets
    translate([metriccano_unit,metriccano_unit/2,metriccano_unit/2]) rotate([90,0,0]) metriccano_nut_cavity_tapered(captive=true);
    translate([metriccano_unit*2,metriccano_unit/2,metriccano_unit/2]) rotate([90,0,0]) metriccano_nut_cavity_tapered(captive=true);
    translate([metriccano_unit,metriccano_unit*3.5,metriccano_unit/2]) rotate([-90,0,0]) metriccano_nut_cavity_tapered(captive=true);
    translate([metriccano_unit*2,metriccano_unit*3.5,metriccano_unit/2]) rotate([-90,0,0]) metriccano_nut_cavity_tapered(captive=true);
}


// Two 2x2 Metriccano plates joined by horizontal and vertical flexures.
// Minimum length 50mm
module y_drive_flexure(fl) {
    translate([metriccano_unit/2,-metriccano_unit,0]) rotate([0,0,90]) metriccano_square_strip(4);
    // Anchor point on actuator
    translate([fl+metriccano_unit*1.5,0,0]) rotate([0,0,90]) metriccano_slot_strip(1.5);
    // Legend
    translate([fl+metriccano_unit*2,0,0])
        difference() {
            cube([8,10,metriccano_unit/2]);
            translate([4,5,-0.3]) rotate([0,0,-90]) linear_extrude(0.6)
                text("Y", size = 4, halign = "center", valign = "center", $fn = 16);
            }
    // Very thin flexure joining them. Slightly short so as not to rub overhanging parts
    translate([metriccano_unit,metriccano_unit/2-0.4,0]) cube([fl,0.8,metriccano_plate_height]);
    // Stress relief
    translate([metriccano_unit,metriccano_unit/2,metriccano_plate_height/2])
        rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
    translate([fl+metriccano_unit+0.4,metriccano_unit/2,metriccano_plate_height/2])
        rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
}

pole_clip_width=3;
pole_stand_rad=16/2-0.2;       // 16mm pole, less a bit for a really tight fit.
pole_stand_arm_length=7;     // Length of stand arm in metriccano units.

// Holder for a 16mm pole to mount a microscope on
module pole_top_arm() difference() {
    // Body of stand with a metriccano rod sticking out
    union () {
        cylinder(h=metriccano_unit,r=pole_stand_rad+pole_clip_width,$fn=64);
        translate([0,pole_clip_width+pole_stand_rad-metriccano_unit/2,0]) scale([1,1,2]) metriccano_slot_strip(pole_stand_arm_length);
    }
    // Hole in the middle for post
    cylinder(h=metriccano_unit*3,r=pole_stand_rad,center=true,$fn=64);
    // A split to give the grip a bit of spring
    translate([0,-pole_stand_rad,0]) cube([1,(pole_stand_rad+pole_clip_width)*2,metriccano_unit*3],center=true);
    // Two screw holes for optional mounting
    translate([pole_clip_width+pole_stand_rad+metriccano_unit,0,metriccano_unit/2])
        rotate([90,0,0]) metriccano_screw_hole(metriccano_unit*4);
    translate([pole_clip_width+pole_stand_rad+metriccano_unit*4,0,metriccano_unit/2])
        rotate([90,0,0]) metriccano_screw_hole(metriccano_unit*4);
}

// Much the same as top arm but has a bit across the bottom to stop the pole falling out
module pole_bottom_arm() union() {
    pole_top_arm();
    // Semi-circular slice on side away from split
    difference() {
        cylinder(h=2,r=pole_stand_rad+pole_clip_width);
        translate([0,-pole_stand_rad,0]) cube([(pole_stand_rad+pole_clip_width)*2,(pole_stand_rad+pole_clip_width)*2,20],center=true);
    }
}

boss_square=15;         // Beefy square section
clamping_pole_arm_length=55;

// A clamp of specified internal radius and wall thickness
module bolted_clamp(int_rad,thick) {
    bolt_shift=boss_square/2+int_rad;
    difference() {
        union() {
            // Clamp round body
            cylinder(h=boss_square,r=int_rad+thick,$fn=64);
            // Clamp clip
            translate([-bolt_shift,0,boss_square/2]) cube(boss_square,center=true);
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
        translate([clamping_pole_arm_length/2,0,boss_square/2])
            cube([clamping_pole_arm_length,boss_square,boss_square],center=true);
        // Rounded arm end
        translate([clamping_pole_arm_length,0,0]) cylinder(h=boss_square,r=boss_square/2,$fn=64);
        // Version stamp
        translate([pole_stand_rad+clamping_pole_arm_length/2,-boss_square/2,boss_square/2])
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

pole_arm_hinge_rad=boss_square/2;
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
// A clamp to grab the USB microscope at the narrow end. Takes the radius of the microscope
module microscope_clamp(mrad=31.5/2) {
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
        }
        // Poke a screw hole and nut slot in the handle end.
        translate([clamp_shaft_len+mrad-8,0,pole_arm_hinge_rad]) rotate([0,90,0])  {
            m3_nut_slot();
            m3_screw_hole(20);
       }
    }
}


// Assembly in 3D for visual test fit
if (false) {
    translate([0,0,structure_height]) rotate([-90,0,0]) outer_frame_unit();
    translate([(inner_mf_offset+flexure_max+2*flexure_clearance+6),flexure_height+0.5,structure_height-flexure_clearance]) rotate([0,-90,0]) rotate([0,0,90]) table_frame_unit();
}

// Build plate A
if (true) {
    outer_frame_unit();
    translate([105,0,0]) outer_frame_unit();
    translate([0,75,0]) table_frame_unit();
    translate([90,75,0]) table_frame_unit();
    translate([30,25,0]) metriccano_adjustment_bracket();
    translate([60,25,0]) metriccano_adjustment_bracket();
    translate([210,122,0]) rotate([0,0,90]) flexured_stage(53);
    translate([10,145,0]) stage_top();
    translate([140,25,0]) metriccano_strip(4);
    translate([140,40,0]) metriccano_strip(4);
    translate([35,45,0]) metriccano_square_strip(4);
    translate([35,100,0]) metriccano_adjustment_bracket(2,1.5);
    translate([125,100,0]) metriccano_adjustment_bracket(2,1.5);
    translate([90,155,0]) y_drive_flexure(51.5);
} else {
    // Build plate B
    translate([5,5,0]) metriccano_square_strip(10);        // Needs 3, Z driver mounts on them.
    translate([5,20,0]) metriccano_square_strip(10);
    translate([5,35,0]) metriccano_square_strip(10);
    translate([115,5,0]) metriccano_square_strip(5);     // Anchors one Z driver support
    translate([5,50,0]) x_axis_mount();
    translate([5,105,0]) y_axis_mount();
    translate([115,25,0]) pole_top_arm();
    translate([115,50,0]) pole_bottom_arm();
    translate([80,125,0]) rotate([0,0,180]) clamping_pole_arm();
    translate([135,85,0]) clamping_pole_hinge();
    translate([135,85,0]) microscope_clamp();
    translate([20,70,0]) m3_thumbscrew_knob(7);
    translate([35,75,0]) m3_thumbscrew_knob(7);
    translate([50,70,0]) m3_thumbscrew_knob(7);
    translate([65,75,0]) m3_thumbscrew_knob(7);
    translate([100,68,0]) m3_thumbscrew_knob(7);
    translate([120,145,0]) clamping_pole_arm();
    translate([165,115,0])  clamping_pole_hinge();
    translate([165,115,0]) rotate([0,0,180]) microscope_clamp();
    translate([174,10,0]) m3_thumbscrew_knob(7);
    translate([190,10,0]) m3_thumbscrew_knob(7);
    translate([190,26,0]) m3_thumbscrew_knob(7);
    translate([190,42,0]) m3_thumbscrew_knob(7);
    translate([190,58,0]) m3_thumbscrew_knob(7);
}
