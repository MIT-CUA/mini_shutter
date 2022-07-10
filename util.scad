//
// OpenSCAD utility modules
//

$fa=0.125; // default minimum facet angle is now 0.5
$fs=0.125; // default minimum facet size is now 0.5 mm
d_inch = 25.4;
screw_tap_dia_14_20   = 0.201 * d_inch;
screw_clear_dia_14_20 = 0.260 * d_inch;
screw_washer_dia_14_20 = 9/16 * d_inch;	// #12 washer

//-----------------------------------------------------------------------------

module slot_without_hull(width=10, length=20, height=2){
     // 
     // Make a slot with rounded ends, given the diameter of the
     // circles at each end, the length, and the height.
     // Do this without using hull(), so that the result
     // can be exported via FreeCAD as a STEP file, for
     // CNC machining, e.g. with Fusion360.
     //
     // hull() cannot be exported by FreeCAD into STEP files.
     //
     // width is used as the circle diameter.
     // a positive element is created; use difference() to cut the slot.
     // the slot is positioned along x, centered on y, and
     // with its bottom at z=0.

     cube_dx = length - width;
     dia = width;

     union(){
	  for (dx=[-1, 1]){
	       translate([dx * cube_dx/2, 0, 0])
		    cylinder(d=dia, h=height);
	  }
	  translate([-cube_dx/2, -width/2, 0]) cube([cube_dx, width, height]);
     }
}

// slot_without_hull(width=10, length=30, height=5);

//-----------------------------------------------------------------------------

module cube_with_rounded_corners(xyz=[20,8,4], dia=2, no_xplus_rounding=false){
     // dia = diameter of cylinder for corners
     //
     // create cube with rounded corners (along z, so this is like a xy plane), without using hull().
     // This allows the cube to be exported to an STEP file using FreeCAD,
     // for manufacturing.
     //
     // rounding is done along the z axis
     //
     // start with a cube, trim the corners at 45deg, then add cylinders
     // at each corner.
     dx = xyz[0];
     dy = xyz[1];
     dz = xyz[2];
     rad = ((dx > 0) && (dy > 0) ? dia/2 : 0);
     cr = rad / 2;
     difference(){
	  cube(xyz);
	  // cutoff four corners
	  for (x=[0, (no_xplus_rounding ? 0 : 1)]){
	       for (y=[0,1]){
		    translate([x*dx, y*dy, 0])
		    mirror([x, y, 0])
		    color("red")
			 translate([cr, cr, -0.01])
			 scale([1,1,1.1])
			 rotate([0, 0, -45])
			 translate([-dx/2, -dy, 0])
			 cube(xyz);
		    }
	  }
     }
     // add cylinders to four corners
     if (dx > 0){
	  for (x=[0, (no_xplus_rounding ? 0 : 1)]){
	       for (y=[0,1]){
		    color("orange")
			 translate([x*(dx-dia), y*(dy-dia), 0])
			 translate([rad, rad, 0])
			 cylinder(d=dia, h=dz);
	       }
	  }
     }
}

//-----------------------------------------------------------------------------

module cube_with_rounded_corners_yz(xyz=[20,8,4], dia=2, no_xplus_rounding=false){
     //
     // rounded cube but in yz plane (round along x)
     // do this by making a xy plane cube, then rotating to flip x <-> z
     //
     dx = xyz[0];
     dy = xyz[1];
     dz = xyz[2];
     translate([0, 0, dz]){
	  rotate([0, 90, 0]){
	       cube_with_rounded_corners(xyz=[dz, dy, dx], dia=dia, no_xplus_rounding=no_xplus_rounding);
	  }
     }
}

module cube_with_rounded_corners_xz(xyz=[20,8,4], dia=2, no_xplus_rounding=false){
     //
     // rounded cube but in xz plane (round along y)
     // do this by making a xy plane cube, then rotating to flip y <-> z
     //
     dx = xyz[0];
     dy = xyz[1];
     dz = xyz[2];
     translate([0, dy, 0]){
	  rotate([90, 0, 0]){
	       cube_with_rounded_corners(xyz=[dx, dz, dy], dia=dia, no_xplus_rounding=no_xplus_rounding);
	  }
     }
}

module screw_with_head_clear(dz, xpos, ypos, head=true, threaded=false){
     color("red")
	  mirror([0,0,1])
	  translate([xpos, ypos , dz-0.01]){
	  cylinder(d=(threaded ? screw_tap_dia_14_20 : screw_clear_dia_14_20), h = 100);
	  if(head){
	       cylinder(d=screw_washer_dia_14_20, h = 10);
	  }
     }
}

// cube_with_rounded_corners(xyz=[20,8,4], dia=2);
// cube_with_rounded_corners(xyz=[4,8,20], dia=2);
// cube_with_rounded_corners_yz(xyz=[4,8,20], dia=2);
cube_with_rounded_corners_xz(xyz=[8,4,20], dia=2);
// cube([4,8,20]);

//-----------------------------------------------------------------------------
// hex nut module

module hexaprism(
	ri =  1.0,  // radius of inscribed circle
	h  =  1.0)  // height of hexaprism
{
     // ra = ri*2/sqrt(3);
     // ra = ri;
     ra = ri / (cos(180/6));	// convert from apothem to circumradius
     // echo("nut dia=", ri*2, ", points dia = ", 2*ra);
     color("red")
	  cylinder(r = ra, h=h, $fn=6, center=false);
}

module hex_nut(thick, dia){
     color("red")
	  translate([0,0,-0.01]) hexaprism(ri=dia/2, h=thick+0.02);
}
