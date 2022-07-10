//
// mini optical shutter for baseplate (1/2" beam height) using
// 4mm diameter coreless DC motor.
//
// motor is easily driven by current from digital output pin
// of RP2040 microcontroller

//-----------------------------------------------------------------------------
// global constants

use <util.scad>;

d_inch = 25.4;
pi = 3.14159;

$fa=0.5; // default minimum facet angle is now 0.5
$fs=0.1; // default minimum facet size is now 0.5 mm

screw_clear_dia_4_40 = 0.120 * d_inch;
screw_tap_dia_4_40   = 0.089 * d_inch;
screw_nut_dia_4_40   = 6.4;
screw_head_clear_dia_4_40 = 5.50;	// actually, pan screw head

screw_clear_dia_6_32 = 0.1450 * d_inch;
screw_tap_dia_6_32   = 0.1065 * d_inch;
screw_nut_dia_6_32   = 7.9;

screw_clear_dia_8_32 = 0.172 * d_inch;
screw_tap_dia_8_32   = 0.1360 * d_inch;
screw_nut_dia_8_32   = 8.7;		// measured from flat to flat
screw_head_clear_dia_8_32 = 7.00;	// hex
screw_washer_clear_dia_8_32 = 9.70;	// thorlabs 8-32 kit washer
screw_self_tap_dia_8_32 = screw_tap_dia_8_32 + 0.5;		// self-tapping for 8-32

// -----------------------------------------------------------------------------
// options


// -----------------------------------------------------------------------------
// mini 4mm coreless dc motor

module motor_4mm_coreless_dc(show=true, drill=false, theta=-45){
     //
     // motor pointing up towards +z, positioned with bottom of cam
     // (closest side of cam to motor) at origin.  shaft has a cam on it.
     //
     // theta = angle of motor cam
     //
     body_dz = 8.2;
     shaft_dia = 0.75;
     cam_outer_dia = 4.0;
     cam_dz = 2.5;
     cam_shaft_dia = 1.5;
     cam_yoff = -0.1;
     oal = 11.4;				// overall length
     slot_dy = 0.5;
     slot_dx = 8;
     module cam(show=true, drill=false){
	  color("blue"){
	       cylinder(d=cam_shaft_dia, h=cam_dz + (drill ? 1 : 0) );	// cam center - on shaft
	       difference(){
		    union(){
			 cylinder(d1=cam_outer_dia + (drill ? 0.4 : 0),	// compensate for burr on print plate
				  d2=cam_outer_dia + (drill ? 0.1 : 0),
				  h=0.4);
			 cylinder(d=cam_outer_dia + (drill ? 0.1 : 0),
				  h=cam_dz + (drill ? 1 : 0));
		    }
		    translate([-5, -10 + cam_yoff, -1])
			 color("red") cube([10, 10, 10]);
	       }
	  }
     }
     union(){
	  extra_dz = (drill ? 8 : 0);				// extra tube length when drilling, for wires to exit
	  extra_dia = (drill ? -0 : 0);			// possibly different diameter when drilling, so motor fits snugly in motor housing
	  translate([0, 0, -oal + cam_dz]){
	       translate([0, 0, -extra_dz]) color("silver"){
		    scale([1 + (drill ? 0.1 : 0), 1, 1])	// for holder, compensate for underhang from top when printing
			 cylinder(d=4 + extra_dia, h=body_dz + extra_dz);	// main cylindrical body of motor
		    if (drill){
			 // cut slot along side of motor, so the motor housing can hold motor with natural spring clamp action
			 translate([-slot_dx, -slot_dy/2, 0])
			      cube([slot_dx, slot_dy, body_dz + extra_dz]);
		    }
	       }
	       translate([0, 0, 0.01]) color("black") cylinder(d=cam_shaft_dia, h=oal-0.01);	// motor shaft
	  }
	  rotate([0, 0, theta])
	       cam(show=show, drill=drill);		// cam at end of shaft
     }
}

// -----------------------------------------------------------------------------
// c05g mount onto baseplate

module baseplate_mount_holes(slen=5){
     //
     // holes for mounting onto baseplate: 8-32 screw and two 2mm pins,
     // compatible with footprint of thorlabs c05 polaris mirror mount.
     //
     // slen = screw length (dz before screw head)
     //
     pin_dia = 2.0;
     pin_dy = 5.0;
     pin_dz = 2.2;
     cylinder(d=screw_clear_dia_8_32, h=20);
     translate([0, 0, slen]) cylinder(d=screw_head_clear_dia_8_32, h=20);
     for(dy=[-1,1]){
	  translate([0, dy*pin_dy, 0]) cylinder(d=pin_dia+0.1, h=pin_dz);
     }
}

// -----------------------------------------------------------------------------
// shutter with mount

module mini_shutter(dz=12.7, show_mount=true, show_motor=true, show_blade=true, drill=false, openclose=0){
     //
     // beam goes along +x, at z=0
     // optical center is center of shutter hole for beam
     // base is dz below beam hight
     //
     // openclose = fraction from open (=0) to close (=1)
     //
     base_dx = 10;
     base_dy = 15.2;
     base_dz = 4;
     motor_housing_dia = 6.5;
     mhd_dz = 8;
     mhd_xoff = -0.85;
     motor_zoff = 0;
     motor_yoff = -6;
     motor_xoff = -1;
     base_xoff = -7;
     beam_clear_dia = 4;

     theta_open = 0 + 4;
     theta_closed = -52;
     theta = openclose * theta_closed;

     shutter_zoff = 0.2;
     shutter_center_thick = 2.6;
     shutter_center_dia = 6;
     shutter_blade_thick = 0.5;
     shutter_blade_yoff = 6;
     shutter_blade_dia = 5;
     shutter_blade_dtheta = 110;

     endstop_angle = -80;
     endstop_yoff = 5;
     endstop_zoff = -2;
     endstop_len = 5;
     endstop_wid = 7;
     endstop_height = 5;

     module motor_position(){
	  // move children to position (and orientation) of motor on the mini shutter
	  // motor is initially along +z
	  // on the mini shutter, the motor is along +x
	  translate([motor_xoff, motor_yoff, motor_zoff])
	       rotate([0, 90, 0])
	       children();
     }

     module shutter_blade(dtheta=90){
	  // fits onto motor cam and blocks (or allows through) the optical beam.
	  // has two arms: one which hits endstop when closed, and the other which
	  // blocks the beam and also hits the endstop when open.
	  //
	  // given in frame of motor.
	  // designed to be glued onto the motor's cam.
	  
	  module one_blade(){
	       translate([0, 0, shutter_zoff]){
		    hull(){
			 cylinder(d=shutter_center_dia, h=shutter_center_thick);
			 translate([0, shutter_blade_yoff, 0]) 
			      cylinder(d=shutter_blade_dia, h=shutter_blade_thick);
		    }
	       }
	  }

	  difference(){
	       for(th=[0, -dtheta]){
		    rotate([0, 0, th]) one_blade();
	       }
	       motor_4mm_coreless_dc(show=false, drill=true);	// cut out motor cam
	  }
     }

     difference(){
	  union(){
	       if (show_mount){
		    color("orange"){
			 hull(){
			      translate([-base_dx/2 + base_xoff, -base_dy/2, -dz])
				   cube([base_dx, base_dy, base_dz]);		// cube for base
			      motor_position()
				   translate([0, 0, -mhd_dz+mhd_xoff]) cylinder(d=motor_housing_dia, h=mhd_dz);
			 }
		    }
		    color("brown"){	// endstop
			 hull(){
			      motor_position(){
				   rotate([0, 0, endstop_angle])
					translate([0, endstop_yoff, endstop_zoff])
					translate([-endstop_wid/2, 0, 0])
					cube_with_rounded_corners([endstop_wid, endstop_len, endstop_height], dia=3);	// endstop cube
			      }
			      translate([-base_dx/2 + base_xoff, -base_dy/2, -dz])
				   cube([base_dx, base_dy, 0.1]);		// thin base for hull
			 }
		    }
	       }
	  }
	  color("red"){
	       translate([base_xoff, 0, -dz-0.1])
		    baseplate_mount_holes();				// holes for 8-32 screw and 2mm pins
	       motor_position()
		    motor_4mm_coreless_dc(show=false, drill=true);	// hole where motor goes
	       rotate([0, 90, 0])					// clearance tube for optical beam
		    translate([0, 0, -15])
		    cylinder(d=beam_clear_dia, h=30);
	  }
	  // cut out endstop based on two positions of the shutter blade
	  color("purple"){
	       for (th=[theta_open + 2, theta_closed - 2]){
		    motor_position()
			 rotate([0, 0, th])
			 shutter_blade(shutter_blade_dtheta);
	       }
	  }
     }
     if (show_blade){
	  color("green"){
	       motor_position()
		    rotate([0, 0, theta])
		    shutter_blade(shutter_blade_dtheta);
	  }
     }
     if (show_motor){
	  motor_position()
	       motor_4mm_coreless_dc(show=true, drill=false, theta=theta-45);
     }
}

//-----------------------------------------------------------------------------

module print_blade(){
     rotate([0, -90, 0])
	  mini_shutter(show_mount=false, show_motor=false, show_blade=true, openclose=0);
}
     
module animation_full_model(){
     openclose = $t;
     mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=openclose);     
}

//-----------------------------------------------------------------------------

// motor_4mm_coreless_dc();
// mini_shutter(show_mount=true, show_motor=true, show_blade=true);
// mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=1);
// mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=0);
// mini_shutter(show_mount=true, show_motor=true, show_blade=false, openclose=0);
// mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=0);

// mini_shutter(show_mount=false, show_motor=false, show_blade=true, openclose=0);			// for showing just blade
mini_shutter(show_mount=true, show_motor=false, show_blade=false, openclose=0);		// for printing mount

// print_blade();

// animation_full_model();
