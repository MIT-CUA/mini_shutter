// illustrate use of hull() for connecting parts

$fa=0.5; // default minimum facet angle is now 0.5
$fs=0.1; // default minimum facet size is now 0.1 mm

module first(){
     color("orange") cube([10, 10, 4]);
     color("blue") translate([0, 0, 8]) rotate([0, 90, 0])
	  cylinder(d=4, h=8);
}

module second(){
     color("orange"){

	  hull(){
	       cube([10, 10, 4]);
	       translate([0, 0, 8]) rotate([0, 90, 0])
		    cylinder(d=4, h=8);
	  }

     }
}

module third(){
     color("blue")
	  translate([0, 0, 8]) rotate([0, 90, 0]) cylinder(d=3, h=12);
     color("orange"){
	  hull(){
	       cube([10, 10, 4]);
	       translate([2, 0, 8]) rotate([0, 90, 0])
		    cylinder(d=4, h=4);
	  }
     }
}

// first();
second();
// third();
