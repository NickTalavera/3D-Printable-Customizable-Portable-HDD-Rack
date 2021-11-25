//---------------------------------
// Quality
$fn = 20;
// Set to 0.01 for higher definition curves (renders slower)
$fs = 0.5;
//---------------------------------
// Includes
include <BOSL2/std.scad>;

//---------------------------------
// Start HDDock Specific Section
//---------------------------------
function rand_int(mins=0,maxs=100)=round(rands(mins,maxs,1)[0]);

function input_to_struct(details, index) =
let (
struct=[],
device_name=str("Device ",index+1),
usb_type=downcase(details[3]),
test1=assert(is_string(usb_type)),
usb_details=struct_val(USB_STRUCT,usb_type),
test2=assert(!is_undef(usb_type),str("Your USB type must be one of",struct_keys(USB_STRUCT))),
conn_height=struct_val(usb_details,"conn_height"),
conn_width=struct_val(usb_details,"conn_width"),
drive_height=details[1],
drive_height_padded=max(drive_height,is_def(conn_height) ? conn_height: 0)+Y_PAD*2,
drive_width_padded=max(details[0],(is_def(conn_width) ? conn_width: 0))+X_PAD*2,
vUSB=max(min(details[5],drive_height_padded),-Y_WALL),
hUSB=max(min(details[4],drive_width_padded-(is_def(conn_width) ? conn_width: 0)),-X_WALL),
d_depth=details [2],
new_struct=struct_set(struct,
["width_padded",drive_width_padded,
"width_unpadded",details[0],
"depth",d_depth,
"type",usb_type,
"conn_height",conn_height,
"conn_width",conn_width,
"height_padded",drive_height_padded,
"height_unpadded",drive_height,
"vUSB",vUSB,
"hUSB",hUSB,
"count",details[6],
"index",index,
"device_name",device_name,
]
),
)
[device_name,new_struct];
function x_at_index(index,val) =   struct_val(DATA_STRUCT[index][1],val) ;

function parse_input(hole_list_str)=
let (
struct=[],
strip_outer=str_strip(hole_list_str," ,"),
//    q=echo(strip_outer),
split_by_comma=str_split(strip_outer, ",", true),
//    f=echo(split_by_comma),
split_out=[for (x=split_by_comma) str_split(str_strip(x, " m"), "x", false)],
//    z=echo(split_out),
to_float=[for (x=split_out) [for (y=x) if(is_num(str_float(y))) str_float(y) else y]],
to_struct=[for (index=[0:1:len(to_float)-1]) input_to_struct(to_float[index],index=index)]
)
to_struct ;

// Show an echo or an assert depending on the parameters
function custom_log(textin, tester, stop_if_fails, skip, show_if_pass=true) =
skip ? (
stop_if_fails ?
assert(tester): show_if_pass || show_if_pass ? echo(textin): undef
)
: undef;




function index_height(index,count)=
let(
test1=assert(count<=x_at_index(index,"count")),
d_height=x_at_index(index,"height_padded"),
is_first=index==0 && count==1,
max_index=MAX_INDEX,
is_max_index = MAX_INDEX==index,
is_last=is_max_index && count == COUNT_AT_MAX_INDEX,
last_add = is_last ? Y_WALL : 0,
first_add = is_first ? FEET_VDIFF : 0
)
d_height
+ last_add
+ Y_WALL
+ first_add
;

function height_to_index2(to_index,to_count,include=false) = 
let (
index_goal=min(to_index,MAX_INDEX),
to_count_N=to_count,
past_first=to_index>=0 && to_count_N>=1,
f_sub=past_first ? index_height(0,1): 0,
r=[for (index=[0:1:index_goal]) [for (count=[
1:1: 
(
to_index == index ? to_count_N :
x_at_index(index,"count"))
])
index_height(index,count) 

]],
rb=flatten(r),
re=include ? rb: list_remove(rb,len(rb)-1),
)
re
;


function height_to_index(to_index,to_count,include=false) = sum(
flatten(height_to_index2(to_index,to_count,include=include)
));

//---------------------------------
// Global variables
//---------------------------------

/* [Input] */
// Coordinates are measured from bottom left corner
// mm units
// <W>x<H>x<D>x<C|Micro|3_Micro|Mini|None>x<X USB Coords>x<Y USB Coords>x<COUNT>
text_list="
80.3x15.7x110.6x3_Microx75x1x1,
78.5x20.7x114.6x3_Microx75x1x1,
75x9.2x107x3_Microx25x3x1
";

// EXAMPLES
// WD My Passport Ultra
// 80.3x15.7x110.6x3_Microx75x1x1
// Seagate Backup Plus
// 78.5x20.7x114.6x3_Microx75x1x1
// Toshiba
// 75x9.2x107x3_Microx25x3x1
// Empty
// 114.5x15.5x114.6xNonex25x3x1

// RANDOM EXAMPLE MAKER
//text_list=str("80x14x100xMicrox",rand_int(-10,80),"x",rand_int(-5,14),"x",rand_int(1,5),", ", rand_int(63.5,90),"x",rand_int(4,10),"x",rand_int(14,90),"x","3_Microx",rand_int(1,90),"x",rand_int(1,10),"x",rand_int(1,5));


//mm
side_wall_thickness=2.5; //[0.3:0.1:10]
//mm
top_bottom_wall_thickness=2.5; //[0.3:0.1:10]
//mm
rear_wall_thickness=2.5; //[0.3:0.1:10]
//mm per each side
vertical_padding=1.5; //[0.1:0.1:16]
//mm per each side
side_padding=0.1; //[0:0.1:6]
//Depth of a rear shield in mm
rear_shield=0; //[0:1:60]
//Rounding of outside corners in mm
rounding_radius=2; //[0:0.2:4]
//If true, left align drives in the cage.
LEFT_ALIGN=false; 
//Diameter of round rubber feet you add separately
rubber_feet_diameter=5; //[0:0.1:15]
rubber_feet_depth=0.4; //[0:0.1:6]
// If your port alignment gets too close to an outer wall,  should it clip?
port_hole_can_intersect_side_walls = true;


/* [USB Tweaking] */
// All measured in mm. I suggest including the plastic of the connector.
USB_C_Height = 6.2;
//mm
USB_C_Width = 10.1;
//mm
USB_3_Micro_Height = 7.5;
//mm
USB_3_Micro_Width = 14.9;
//mm
USB_Micro_Height = 5.9;
//mm
USB_Micro_Width = 10.6;
//mm
USB_Mini_Height = 6;
//mm
USB_Mini_Width = 10;
//Depth of the metal portion of the USB to remove further plastic to accomodate
usb_connector_depth=3;



/* [Debugging] */
// Prints more details to the log.  Checks against max height.
ENABLE_DEBUGGING=false;
// Height limit in mm
MAX_BOX_HEIGHT = 88;


/* [Hidden] */
//---------------------------------
//Constrain input variables
//---------------------------------
USB_CONNECTOR_DEPTH=usb_connector_depth;
CAN_INTERSECT = port_hole_can_intersect_side_walls;
RUBBER_FEET_DEPTH_N=rubber_feet_depth;
RUBBER_FEET_DIAMETER_N=rubber_feet_diameter;
Y_PAD = vertical_padding;
X_PAD = side_padding;
REAR_WALL=min(max(rear_wall_thickness,0.3),250);
Y_WALL=min(max(top_bottom_wall_thickness,0.3),250);
X_WALL=min(max(side_wall_thickness,0.3),250);
SHIELD_DEPTH=min(max(rear_shield,0),250);
//---------------------------------
//Hidden constants
//---------------------------------
SPACER=0.02;
//---------------------------------
//Calculated and hidden variables
//---------------------------------
USB_STRUCT = [
["c",[
["conn_height",USB_C_Height],
["conn_width",USB_C_Width]
]
],
["3_micro",[
["conn_height",USB_3_Micro_Height],
["conn_width",USB_3_Micro_Width]]
],
["micro",[
["conn_height",USB_Micro_Height],
["conn_width",USB_Micro_Width]
],
],
["mini",[
["conn_height",USB_Micro_Height],
["conn_width",USB_Micro_Width]
],
]
];
DATA_STRUCT=parse_input(text_list);
MAX_INDEX=len(DATA_STRUCT)-1;
COUNT_AT_MAX_INDEX=x_at_index(MAX_INDEX,"count");

if (ENABLE_DEBUGGING) {
  echo(str("Your total height is ",CAGE_HEIGHT,"mm"));
  echo(str("Your total width is ",CAGE_WIDTH,"mm"));
  echo(str("Top bottom wall thickness ",Y_WALL));
  echo(str("Vertical padding ",Y_PAD));
  echo(str("MAX_INDEX ",Y_PAD));
  echo(str("COUNT_AT_MAX_INDEX ",COUNT_AT_MAX_INDEX));
  for (kv=DATA_STRUCT){
    details = kv[1];
    usb_type=struct_val(details,"type");
    usb_details=struct_val(USB_STRUCT,usb_type);
    echo(str("For ",kv[0],"\nThe data made is:\n",details));
  }
}


FEET_VDIFF = max(RUBBER_FEET_DEPTH_N-Y_WALL,0);
TOTAL_COUNT = sum([for (x=[0:1:MAX_INDEX]) struct_val(DATA_STRUCT[x][1],"count")]);
D_SPACED = SPACER*2;
CAGE_HEIGHT = height_to_index(to_index=MAX_INDEX,to_count= COUNT_AT_MAX_INDEX,include=true);
CAGE_HEIGHT_SPACED = CAGE_HEIGHT + D_SPACED;
CAGE_WIDTH = max([for (x=[0:1:MAX_INDEX])
(struct_val(DATA_STRUCT[x][1],"width_padded")+X_WALL*2)]);
CAGE_WIDTH_SPACED = CAGE_WIDTH + D_SPACED;
CAGE_DEPTH = max([for (x=[0:1:MAX_INDEX])
(struct_val(DATA_STRUCT[x][1],"depth")+REAR_WALL)])+SHIELD_DEPTH;
CAGE_DEPTH_SPACED = CAGE_DEPTH + D_SPACED;



module all_feet() {
  // Add 4 feet
  if (RUBBER_FEET_DEPTH_N > 0 && RUBBER_FEET_DIAMETER_N > 0) {
    translate([0,0,RUBBER_FEET_DEPTH_N-SPACER])
    union() {
      x=RUBBER_FEET_DIAMETER_N+X_WALL;
      y=-RUBBER_FEET_DEPTH_N-SPACER;
      zu=RUBBER_FEET_DIAMETER_N+REAR_WALL+SHIELD_DEPTH;
      zd=-RUBBER_FEET_DIAMETER_N-REAR_WALL+CAGE_DEPTH;
      translate([x,zd,y])
      feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+SPACER);
      
      translate([CAGE_WIDTH-x,zd,y])
      feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+SPACER);
      
      translate([x,zu,y])
      feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+SPACER);
      
      translate([CAGE_WIDTH+-x,zu,y])
      feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+SPACER);
    }
  }
}

module feet(drive_height, drive_width, d_depth) {
  if (RUBBER_FEET_DEPTH_N > 0 && RUBBER_FEET_DIAMETER_N > 0) {
    cylinder(r=RUBBER_FEET_DIAMETER_N, h=RUBBER_FEET_DEPTH_N, center=false);  
  }
}

module chamber(details) {
  drive_height = struct_val(details, "height_padded");
  drive_width = struct_val(details, "width_padded");
  drive_depth = struct_val(details, "depth");
  index = struct_val(details, "index");
  count = struct_val(details, "count");
  lr_adjust = LEFT_ALIGN && (drive_width*2+X_WALL*2 != CAGE_WIDTH)  ? CAGE_WIDTH-drive_width-X_WALL*2: 0;
  for (curr_count=[1:1:count]) {
    height_so_far = height_to_index(to_index=index, to_count=curr_count);
    first = curr_count==1 && index==0;
    translate([X_WALL, REAR_WALL, Y_WALL])
    translate([lr_adjust, CAGE_DEPTH-drive_depth, height_so_far + (!first?0:FEET_VDIFF)])
    color("red")
    cube(size = [drive_width, drive_depth, drive_height], center=false);
  }
}


module ports(details) {
  drive_depth = struct_val(details, "depth");
  drive_width = struct_val(details, "width_padded");
  USB_type = struct_val(details, "type");
  vUSB = struct_val(details, "vUSB");
  hUSB = struct_val(details, "hUSB");
  count = struct_val(details, "count");
  conn_height = struct_val(details, "conn_height");
  conn_width = struct_val(details, "conn_width");
  index = struct_val(details, "index");
  intersect_shield = (!CAN_INTERSECT ? SHIELD_DEPTH: 0);
  
  //Calculate port placement and size details
  conn_depth = CAGE_DEPTH-drive_depth+REAR_WALL+D_SPACED*3.5-intersect_shield+min(USB_CONNECTOR_DEPTH,drive_depth-D_SPACED);
  conn_x_pos =  hUSB + (LEFT_ALIGN ? CAGE_WIDTH-drive_width-X_WALL : X_WALL);
  conn_y_pos = intersect_shield-D_SPACED*3 + conn_depth;
  conn_z_pos = vUSB + Y_WALL ;
  conn_w = max((conn_height<=conn_width? conn_width/2 :conn_height/2),CAGE_WIDTH);
  conn_h = (conn_height>conn_width? conn_width :conn_height);
  
    
  //Make the ports
  translate([0,conn_y_pos,0])
  translate([conn_x_pos,0,0])
  translate([0,0,conn_z_pos])
  for (curr_count=[1:1:count]) {
    if (is_def(conn_height) && is_def(conn_width) && USB_type != "none") {
      //        hull() 
      {
        height_so_far = height_to_index(to_index=index, to_count=curr_count);
        first=curr_count==1 && index==0;
        last=curr_count==COUNT_AT_MAX_INDEX && index==MAX_INDEX;
        translate([0, 0, height_so_far + (!first?0:FEET_VDIFF)]) // X_PAD Fix?
        port( conn_height,conn_width,conn_depth,vUSB,hUSB);      
      }
    }
  }
}



module port_crop(details) {
  drive_width = struct_val(details, "width_padded");
  drive_height = struct_val(details, "height_padded");
  drive_depth = struct_val(details, "depth");
  USB_type = struct_val(details, "type");
  vUSB = struct_val(details, "vUSB");
  hUSB = struct_val(details, "hUSB");
  count = struct_val(details, "count");
  conn_height = struct_val(details, "conn_height");
  conn_width = struct_val(details, "conn_width");
  index = struct_val(details, "index");
  conn_w = max((conn_height<=conn_width? conn_width/2 :conn_height/2),CAGE_WIDTH);
  conn_h = (conn_height>conn_width? conn_width :conn_height);
  h_gt_w = drive_height+conn_h;
  
  if (is_def(conn_height) && is_def(conn_width) && USB_type != "none" && !CAN_INTERSECT) {
    // Non indented port crop
    mirror([(LEFT_ALIGN ? 0: 1),0])
    translate([(LEFT_ALIGN ? CAGE_WIDTH: 0)-SPACER-X_WALL,  -D_SPACED,0])
    cube(size=[CAGE_WIDTH_SPACED, CAGE_DEPTH_SPACED, CAGE_HEIGHT_SPACED], center=false);
    // Bottom port crop
    mirror([0,0,1])
    translate([-SPACER,0,-Y_WALL-D_SPACED])
    cube(size=[CAGE_WIDTH_SPACED, CAGE_DEPTH_SPACED, h_gt_w], center=false);
    for (curr_count=[1:1:count]) {
      height_so_far = height_to_index(to_index=index, to_count=curr_count);
      first = curr_count==1 && index==0;
      last = curr_count==COUNT_AT_MAX_INDEX && index==MAX_INDEX;
      translate([0, 0, height_so_far + (!first?0:FEET_VDIFF)])
      //Indented port crop
      translate([
      (LEFT_ALIGN ? -1: 1)*((LEFT_ALIGN ? 0: CAGE_WIDTH)+conn_w+(CAN_INTERSECT?+SPACER*3:X_WALL*2)+SPACER), 
      -SPACER*3,
      0
      ])
      mirror([(LEFT_ALIGN ? 0: 1),0,0])
      cube(size=[(CAN_INTERSECT?0:CAGE_WIDTH-drive_width+X_WALL)+conn_w, 
      CAGE_DEPTH+SPACER*10, 
      h_gt_w + (last ? Y_WALL+SPACER : 0)
      ], center=false);
    }
  }
}


module port(conn_height,conn_width,conn_depth,vUSB,hUSB) {
  hole_radius = min(conn_height,conn_width)/2;
  echo("hole_radius",hole_radius);
  echo("conn_height",conn_height);
  echo("conn_width",conn_width);
  echo();
  xrot(90)
  //  hull()
  {
    //    translate([
    //      conn_height<=conn_width ? conn_height/2-hole_radius:0,
    //      conn_height>conn_width ? conn_height/2-hole_radius:0
    //      ])
    //    cylinder(r=hole_radius, h=conn_depth, center=false);
    //    
    
    //        translate([(min(conn_height,conn_width))/2,
    //      0
    //      ])  
    cylinder(r=hole_radius, h=conn_depth, center=false);
  }
}


module full_box(data_struct) {
  //    difference() 
  {
    difference() 
    {
      color("pink")
      // Hard Drive Slots
      if (rounding_radius == 0) {
        cube(size=[CAGE_WIDTH, CAGE_DEPTH, CAGE_HEIGHT], center=false);
      }
      else {
        roundedcube(size = [CAGE_WIDTH, CAGE_DEPTH, CAGE_HEIGHT  ], center = false, radius = rounding_radius, apply_to = "all");
      }
      
      union() {
        for (details=[for (x=data_struct) x[1]]) {
          chamber(details=details);
        }
        if (SHIELD_DEPTH > 0) {
          translate([X_WALL, -0.1, -SPACER])
          color([1,0.5,0])
          cube(size=[CAGE_WIDTH-X_WALL*2,SHIELD_DEPTH,CAGE_HEIGHT-Y_WALL+SPACER], center=false);
        }
        
        all_feet() ;
      }
    }
    difference() 
    {
      for (details=[for (x=data_struct) x[1]]) {
        ports(details=details);
      }
      for (details=[for (x=data_struct) x[1]]) {
        port_crop(details=details);
      }
    }
    
    
  }
}

full_box(DATA_STRUCT);


//-------------------------
// BOSL2 Functions
// Copyright (c) 2017-2019, Revar Desmera
// All rights reserved.
// https://github.com/revarbat/BOSL2/blob/0e999084406aad0c091460e92711c28ef5253ded/LICENSE
//
function str_split(str,sep,keep_nulls=true) =
!keep_nulls ? _remove_empty_strs(str_split(str,sep,keep_nulls=true)) :
is_list(sep) ? _str_split_recurse(str,sep,i=0,result=[]) :
let( cutpts = concat([-1],sort(flatten(search(sep, str,0))),[len(str)]))
[for(i=[0:len(cutpts)-2]) substr(str,cutpts[i]+1,cutpts[i+1]-cutpts[i]-1)];

function _str_split_recurse(str,sep,i,result) =
i == len(sep) ? concat(result,[str]) :
let(
pos = search(sep[i], str),
end = pos==[] ? len(str) : pos[0]
)
_str_split_recurse(
substr(str,end+1),
sep, i+1,
concat(result, [substr(str,0,end)])
);

function _remove_empty_strs(list) =
list_remove(list, search([""], list,0)[0]);

function substr(str, pos=0, len=undef) =
is_list(pos) ? _substr(str, pos[0], pos[1]-pos[0]+1) :
len == undef ? _substr(str, pos, len(str)-pos) :
_substr(str,pos,len);

function _substr(str,pos,len,substr="") =
len <= 0 || pos>=len(str) ? substr :
_substr(str, pos+1, len-1, str(substr, str[pos]));
function flatten(l) =
!is_list(l)? l :
[for (a=l) if (is_list(a)) (each a) else a];

function struct_val(struct, keyword, default=undef) =
assert(is_def(keyword),"keyword is missing")
let(ind = search([keyword],struct)[0])
ind == [] ? default : struct[ind][1];
function struct_set(struct, keyword, value=undef, grow=true) =
!is_list(keyword)? (
let( ind=search([keyword],struct,1,0)[0] )
ind==[]? (
assert(grow,str("Unknown keyword \"",keyword))
concat(struct, [[keyword,value]])
) : list_set(struct, [ind], [[keyword,value]])
) : _parse_pairs(struct,keyword,grow);


function _parse_pairs(spec, input, grow=true, index=0, result=undef) =
assert(len(input)%2==0,"Odd number of entries in [keyword,value] pair list")
let( result = result==undef ? spec : result)
index == len(input) ? result :

_parse_pairs(spec,input,grow,index+2,struct_set(result, input[index], input[index+1],grow));

function sort(list, idx=undef) =
assert(is_list(list)||is_string(list), "Invalid input." )
is_string(list)? str_join(sort([for (x = list) x],idx)) :
!is_list(list) || len(list)<=1 ? list :
is_homogeneous(list,1)
?   let(size = list_shape(list[0]))
size==0 ?         _sort_scalars(list)
: len(size)!=1 ?  _sort_general(list,idx)
: is_undef(idx) ? _sort_vectors(list)
: assert( _valid_idx(idx) , "Invalid indices.")
_sort_vectors(list,[for(i=idx) i])
: _sort_general(list,idx);
function is_homogeneous(l, depth=10) =
!is_list(l) || l==[] ? false :
let( l0=l[0] )
[] == [for(i=[1:1:len(l)-1]) if( ! _same_type(l[i],l0, depth+1) )  0 ];

function is_homogenous(l, depth=10) = is_homogeneous(l, depth);


function _same_type(a,b, depth) =
(depth==0) ||
(is_undef(a) && is_undef(b)) ||
(is_bool(a) && is_bool(b)) ||
(is_num(a) && is_num(b)) ||
(is_string(a) && is_string(b)) ||
(is_list(a) && is_list(b) && len(a)==len(b)
&& []==[for(i=idx(a)) if( ! _same_type(a[i],b[i],depth-1) ) 0] );
function list_shape(v, depth=undef) =
assert( is_undef(depth) || ( is_finite(depth) && depth>=0 ), "Invalid depth.")
! is_list(v) ? 0 :
(depth == undef)
?   concat([len(v)], _list_shape_recurse(v))
:   (depth == 0)
?  len(v)
:  let( dimlist = _list_shape_recurse(v))
(depth > len(dimlist))? 0 : dimlist[depth-1] ;
function _sort_scalars(arr) =
len(arr)<=1 ? arr :
let(
pivot   = arr[floor(len(arr)/2)],
lesser  = [ for (y = arr) if (y  < pivot) y ],
equal   = [ for (y = arr) if (y == pivot) y ],
greater = [ for (y = arr) if (y  > pivot) y ]
)
concat( _sort_scalars(lesser), equal, _sort_scalars(greater) );

function list_remove(list, ind) =
assert(is_list(list), "Invalid list in list_remove")
is_finite(ind) ?
(
(ind<0 || ind>=len(list)) ? list
:
[
for (i=[0:1:ind-1]) list[i],
for (i=[ind+1:1:len(list)-1]) list[i]
]
)
:   ind==[] ? list
:   assert( is_vector(ind), "Invalid index list in list_remove")
let(sres = search(count(list),ind,1))
[
for(i=idx(list))
if (sres[i] == [])
list[i]
];

function downcase(str) =
str_join([for(char=str) let(code=ord(char)) code>=65 && code<=90 ? chr(code+32) : char]);
function is_finite(x) = is_num(x) && !is_nan(0*x);
function str_strip(s,c) = str_strip_trailing(str_strip_leading(s,c),c);
function str_strip_trailing(s,c) = substr(s,len=len(s)-_str_count_trailing(s,c));
function str_strip_leading(s,c) = substr(s,pos=_str_count_leading(s,c));
function substr(str, pos=0, len=undef) =
is_list(pos) ? _substr(str, pos[0], pos[1]-pos[0]+1) :
len == undef ? _substr(str, pos, len(str)-pos) :
_substr(str,pos,len);
function is_nan(x) = (x!=x);
function _substr(str,pos,len,substr="") =
len <= 0 || pos>=len(str) ? substr :
_substr(str, pos+1, len-1, str(substr, str[pos]));

function _str_count_leading(s,c,_i=0) =
(_i>=len(s)||!in_list(s[_i],[each c]))? _i :
_str_count_leading(s,c,_i=_i+1);

function in_list(val,list,idx) =
assert(is_list(list),"Input is not a list")
assert(is_undef(idx) || is_finite(idx), "Invalid idx value.")
let( firsthit = search([val], list, num_returns_per_match=1, index_col_num=idx)[0] )
firsthit==[] ? false
: is_undef(idx) && val==list[firsthit] ? true
: is_def(idx) && val==list[firsthit][idx] ? true
// first hit was found but didn't match, so try again with all hits
: let ( allhits = search([val], list, 0, idx)[0])
is_undef(idx) ? [for(hit=allhits) if (list[hit]==val) 1] != []
: [for(hit=allhits) if (list[hit][idx]==val) 1] != [];

function is_def(x) = !is_undef(x);
function struct_keys(struct) =
[for(entry=struct) entry[0]];
function _str_count_trailing(s,c,_i=0) =
(_i>=len(s)||!in_list(s[len(s)-1-_i],[each c]))? _i :
_str_count_trailing(s,c,_i=_i+1);


function str_float(str) =
str==undef ? undef :
len(str) == 0 ? 0 :
in_list(str[1], ["+","-"]) ? (0/0) : // Don't allow --3, or +-3
str[0]=="-" ? -str_float(substr(str,1)) :
str[0]=="+" ?  str_float(substr(str,1)) :
let(esplit = str_split(str,"eE") )
len(esplit)==2 ? str_float(esplit[0]) * pow(10,str_int(esplit[1])) :
let( dsplit = str_split(str,["."]))
str_int(dsplit[0])+str_int(dsplit[1])/pow(10,len(dsplit[1]));

function str_int(str,base=10) =
str==undef ? undef :
len(str)==0 ? 0 :
let(str=downcase(str))
str[0] == "-" ? -_str_int_recurse(substr(str,1),base,len(str)-2) :
str[0] == "+" ?  _str_int_recurse(substr(str,1),base,len(str)-2) :
_str_int_recurse(str,base,len(str)-1);

function _str_int_recurse(str,base,i) =
let(
digit = search(str[i],"0123456789abcdef"),
last_digit = digit == [] || digit[0] >= base ? (0/0) : digit[0]
) i==0 ? last_digit :
_str_int_recurse(str,base,i-1)*base + last_digit;
function downcase(str) =
str_join([for(char=str) let(code=ord(char)) code>=65 && code<=90 ? chr(code+32) : char]);

function str_join(list,sep="",_i=0, _result="") =
_i >= len(list)-1 ? (_i==len(list) ? _result : str(_result,list[_i])) :
str_join(list,sep,_i+1,str(_result,list[_i],sep));
function sum(v, dflt=0) =
v==[]? dflt :
assert(is_consistent(v), "Input to sum is non-numeric or inconsistent")
is_finite(v[0]) || is_vector(v[0]) ? [for(i=v) 1]*v :
_sum(v,v[0]*0);

function _sum(v,_total,_i=0) = _i>=len(v) ? _total : _sum(v,_total+v[_i], _i+1);
function is_consistent(list, pattern) =
is_list(list)
&& (len(list)==0
|| (let(pattern = is_undef(pattern) ? _list_pattern(list[0]): _list_pattern(pattern) )
[]==[for(entry=0*list) if (entry != pattern) entry]));

//Creates a list with the same structure of `list` with each of its elements replaced by 0.
function _list_pattern(list) =
is_list(list)
? [for(entry=list) is_list(entry) ? _list_pattern(entry) : 0]
: 0;


//END BOSL2

// RoundedCorners from Daniel Shaw, copied from groovenectar's version on 11-21-2021
// https://gist.github.com/groovenectar/92174cb1c98c1089347e
// No license is attached. If you are an owner, please contact me if incorrect.
// More information: https://danielupshaw.com/openscad-rounded-corners/


module roundedcube(size = [1, 1, 1], center = false, radius = 0.5, apply_to = "all") {
  // If single value, convert to [x, y, z] vector
  size = (size[0] == undef) ? [size, size, size] : size;
  
  translate_min = radius;
  translate_xmax = size[0] - radius;
  translate_ymax = size[1] - radius;
  translate_zmax = size[2] - radius;
  
  diameter = radius * 2;
  
  obj_translate = (center == false) ?
  [0, 0, 0] : [
  -(size[0] / 2),
  -(size[1] / 2),
  -(size[2] / 2)
  ];
  
  translate(v = obj_translate) {
    hull() {
      for (translate_x = [translate_min, translate_xmax]) {
        x_at = (translate_x == translate_min) ? "min" : "max";
        for (translate_y = [translate_min, translate_ymax]) {
          y_at = (translate_y == translate_min) ? "min" : "max";
          for (translate_z = [translate_min, translate_zmax]) {
            z_at = (translate_z == translate_min) ? "min" : "max";
            
            translate(v = [translate_x, translate_y, translate_z])
            if (
            (apply_to == "all") ||
            (apply_to == "xmin" && x_at == "min") || (apply_to == "xmax" && x_at == "max") ||
            (apply_to == "ymin" && y_at == "min") || (apply_to == "ymax" && y_at == "max") ||
            (apply_to == "zmin" && z_at == "min") || (apply_to == "zmax" && z_at == "max")
            ) {
              sphere(r = radius);
            } else {
              rotate = 
              (apply_to == "xmin" || apply_to == "xmax" || apply_to == "x") ? [0, 90, 0] : (
              (apply_to == "ymin" || apply_to == "ymax" || apply_to == "y") ? [90, 90, 0] :
              [0, 0, 0]
              );
              rotate(a = rotate)
              cylinder(h = diameter, r = radius, center = true);
            }
          }
        }
      }
    }
  }
}

module xrot(a=0, p, cp)
{
  assert(is_undef(p), "Module form `xrot()` does not accept p= argument.");
  if (a==0) {
    children();  // May be slightly faster?
  } else if (!is_undef(cp)) {
    translate(cp) rotate([a, 0, 0]) translate(-cp) children();
  } else {
    rotate([a, 0, 0]) children();
  }
}

function xrot(a=0, p=_NO_ARG, cp) = rot([a,0,0], cp=cp, p=p);