// maus_complementary.scad - RepRapMicron Maus vertical complimentary flexure stage
// (C) 2025 vik@diamondage.co.nz Released under the GPLV3 or later.
// Notes:
// Requires 3 standard Maus axis drivers and probe holder parts
// Base should be secured to 10mm pitch perforated sheet, 13 x 11 holes
//  avaliable as metriccano_baseboard.svg for lasercutting
// The frame has to be wide enough to hold your UV light source centrally
// It is a Very Good Idea(TM) to keep the width in Metriccano (10mm) units.
// Printed on Prusa Mk4, 0.2mm layers, 20% infill, 2 v shells, 5 h shells

include <../library/m3_parts.scad>
include <../library/metriccano.scad>
include <../library/nema17lib.scad>

version_string="MAUSC V0.02";

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
                scale([1,1,frame_thick/metriccano_unit*2])
                    metriccano_strip(tf_mount_holes,squared=true);
        cube([y_axis_width-2*inner_tf_offset,frame_thick,flexure_height*1.5+edge_clearance]);
    }
}

// The dimensions of the well that lets UV light up from under the stage
module light_well() {
    well_size=metriccano_unit/2+0.5;
    translate([metriccano_unit*2.5,metriccano_unit*1.5,0])
        hull() {
            translate([well_size,well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([-well_size,well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([well_size,-well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([-well_size,-well_size,0])
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
                metriccano_plate(6,4);
                // Version text
                translate([-metriccano_unit*0.5,metriccano_unit*1.5,metriccano_unit/4]) rotate([0,-90,0]) rotate([0,0,90])
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

// This plate fits on top of the stage and has cutouts for magnets in it
magnet_x=9.6;
magnet_y=29.5;
magnet_z=2;
st_base_thick=1;
st_plate_height=st_base_thick+magnet_z+m3_screw_head_height+0.2;  // Hide screw heads under the magnet.
module stage_top() {
    difference() {
        // Scale the plate to be the same thickness as a magnet plus a screw head
        scale([1,1,(st_plate_height)/metriccano_unit*2]) metriccano_plate(6,4);
        // Chop out the light well
        light_well();
        // Holes for a screw head underneath to take grounding post
        translate([metriccano_unit,0,m3_screw_head_height+0.2]) rotate([180,0,0]) m3_screw_cavity();
        translate([metriccano_unit*4,metriccano_unit*3,m3_screw_head_height+0.2]) rotate([180,0,0]) m3_screw_cavity();
        // Holes for screw heads
        translate([0,metriccano_unit,st_base_thick]) m3_screw_cavity();
        translate([0,2*metriccano_unit,st_base_thick]) m3_screw_cavity();
        translate([5*metriccano_unit,metriccano_unit,st_base_thick]) m3_screw_cavity();
        translate([5*metriccano_unit,2*metriccano_unit,st_base_thick]) m3_screw_cavity();
        // Chop out magnet slots. Insetting from ends by 3mm allows the touchplate on a slide to get to the centre of the stage.
        translate([3,metriccano_unit*1.5,st_plate_height-magnet_z/2]) cube([magnet_x,magnet_y,magnet_z+0.01],center=true);
        translate([metriccano_unit*5-3,metriccano_unit*1.5,st_plate_height-magnet_z/2]) cube([magnet_x,magnet_y,magnet_z+0.01],center=true);
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

// Heavy square double bracket to hang X axis on. Needs a bit more displacement on the X axis for the driver flexure
module x_axis_mount() union() {
    // U-shaped bracket
    metriccano_square_strip(9);
    translate([0,metriccano_unit*4,0]) metriccano_square_strip(9);
    rotate([0,0,90]) metriccano_square_strip(5);
    translate([metriccano_unit*8,metriccano_unit,0]) rotate([0,0,90]) metriccano_square_strip(3);
    // Single unit knobs on the top of the U arms to give more stable mount points
    translate([metriccano_unit*9.5,0,metriccano_unit/2]) rotate([0,-90,0]) metriccano_square_strip(2);
    translate([metriccano_unit*9.5,metriccano_unit*4,metriccano_unit/2]) rotate([0,-90,0]) metriccano_square_strip(2);
}


// Two 2x2 Metriccano plates joined by horizontal and vertical flexures.
// Minimum length 50mm
module y_drive_flexure(fl) {
    translate([metriccano_unit/2,-metriccano_unit,0]) rotate([0,0,90]) metriccano_square_strip(4);
    // Anchor point on actuator
    translate([fl+metriccano_unit*1.5,0,0]) rotate([0,0,90]) metriccano_slot_strip(1.5);
    // Very thin flexure joining them. Slightly short so as not to rub overhanging parts
    translate([metriccano_unit,metriccano_unit/2-0.4,0]) cube([fl,0.8,metriccano_plate_height]);
    // Stress relief
    translate([metriccano_unit,metriccano_unit/2,metriccano_plate_height/2])
        rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
    translate([fl+metriccano_unit+0.4,metriccano_unit/2,metriccano_plate_height/2])
        rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
}

// Assembly in 3D for visual test fit
if (false) {
    translate([0,0,structure_height]) rotate([-90,0,0]) outer_frame_unit();
    translate([(inner_mf_offset+flexure_max+2*flexure_clearance+6),flexure_height+0.5,structure_height-flexure_clearance]) rotate([0,-90,0]) rotate([0,0,90]) table_frame_unit();
}

// Prototyping only
//plain_stage();
//brace_with_nema17();
//bracing_beam();

// Build plate A
if (true) {
    outer_frame_unit();
    translate([105,0,0]) outer_frame_unit();
    translate([0,75,0]) table_frame_unit();
    translate([90,75,0]) table_frame_unit();
    translate([30,30,0]) metriccano_adjustment_bracket();
    translate([60,30,0]) metriccano_adjustment_bracket();
    translate([200,122,0]) rotate([0,0,90]) flexured_stage(53);
    translate([10,145,0]) stage_top();
    translate([140,25,0]) metriccano_square_strip(4);
    translate([140,40,0]) metriccano_square_strip(4);
    translate([170,90,0]) metriccano_strip(4);
    translate([170,105,0]) metriccano_strip(4);
    translate([35,100,0]) metriccano_adjustment_bracket(2,1.5);
    translate([125,100,0]) metriccano_adjustment_bracket(2,1.5);
}
// Build plate B
if (false) {
    translate([5,5,0]) metriccano_square_strip(10);        // Needs 3, Z driver mounts on them.
    translate([5,20,0]) metriccano_square_strip(10);
    translate([5,35,0]) metriccano_square_strip(10);
    translate([115,5,0]) metriccano_square_strip(5);     // Anchors one Z driver support
    translate([5,50,0]) x_axis_mount();
    translate([5,105,0]) y_axis_mount();
    translate([110,40,0]) y_drive_flexure(51.5);
}

// Bits you will need
//table_frame_unit();   // Needs 2
//outer_frame_unit();   // Needs 2
//metriccano_adjustment_bracket();    // Needs 2, attaches X & Y drivers to stage flexures
//flexured_stage(53);
//stage_top();
//metriccano_square_strip(4);     // Needs 2, stage sits on them
//metriccano_strip(4);     // Needs 2, stage sits on them
//metriccano_adjustment_bracket(2,1.5);    // Needs 2, anchor base end of two Z driver supports
//metriccano_square_strip(10);        // Needs 3, Z driver mounts on them.
//metriccano_square_strip(5);     // Anchors one Z driver support
//x_axis_mount();
//y_axis_mount();
//y_drive_flexure(51.5);
