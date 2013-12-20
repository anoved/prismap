// Generated with Prismap, written by Jim DeVona
// https://github.com/anoved/prismap

/* [Data] */

// Must be less than or equal to the minimum data value.
lower_bound = 0;

// Must be greater than or equal to the maximum data value.
upper_bound = 30;

// Connecticut
data0 = 14;

// Massachusetts
data1 = 21;

// Maine
data2 = 12;

// New Hampshire
data3 = 15;

// New Jersey
data4 = 6;

// New York
data5 = 28;

// Pennsylvania
data6 = 17;

// Rhode Island
data7 = 20;

// Vermont
data8 = 12;

// preview[view:south, tilt:top diagonal]

/* [Model Options] */

// Maximum x size in output units (typically mm).
x_size_limit = 80;

// Maximum y size in output units (typically mm).
y_size_limit = 80;

// Maximum z size in output units (typically mm).
z_size_limit = 10;

// Must be less than z size limit. Set to 0 to disable floor. (Floor thickness is automatically set to wall thickness if floor is disabled and walls are enabled.)
floor_thickness = 1; // [0:10]

// Must be less than x and y size limits. Set to 0 to disable walls.
wall_thickness = 1; // [0:10]

/* [Hidden] */

data = [data0, data1, data2, data3, data4, data5, data6, data7, data8];
for (dv = data) {
	if (lower_bound > dv) {
		echo("Warning: lower bound should be less than or equal to minimum data value.");
	}
	if (upper_bound < dv) {
		echo("Warning: upper bound should be greater than or equal to maximum data value.");
	}
}

if (floor_thickness >= z_size_limit) {
	echo("Warning: floor thickness should be less than z size limit.");
}

if (wall_thickness >= x_size_limit || wall_thickness >= y_size_limit) {
	echo("Warning: wall thickness should be less than x and y size limit.");
}

x_extent = 13.5333;

y_extent = 8.52185;

z_scale = (z_size_limit - ((floor_thickness == 0 && wall_thickness > 0) ? wall_thickness : floor_thickness)) / (upper_bound - lower_bound);

x_scale = (x_size_limit - wall_thickness) / x_extent;

y_scale = (y_size_limit - wall_thickness) / y_extent;

xy_scale = min(x_scale, y_scale);

function extrusionheight(value) = ((floor_thickness == 0 && wall_thickness > 0) ? wall_thickness : floor_thickness) + (z_scale * (value - lower_bound));

Prismap();

module Floor() {
	translate([-80.5203, 38.9411, 0])
		cube([x_extent, y_extent, floor_thickness > 0 ? floor_thickness : wall_thickness]);
}

module Walls() {
	translate([((x_extent / -2) * xy_scale) - wall_thickness, (y_extent / -2) * xy_scale, 0])
		cube([wall_thickness, (y_extent * xy_scale) + wall_thickness, z_size_limit]);
	translate([(x_extent / -2) * xy_scale, (y_extent / 2) * xy_scale, 0])
		cube([x_extent * xy_scale, wall_thickness, z_size_limit]);
}

module feature0(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-71.80083571617948, 42.0119630435785],
			[-71.79579299137777, 41.51995130605979],
			[-71.80452712257028, 41.41674573571654],
			[-71.82987258252152, 41.39274060784768],
			[-71.84235305174761, 41.3355128224615],
			[-71.92994704922964, 41.34103894571917],
			[-72.2652717690525, 41.29166638524202],
			[-72.3710591266036, 41.312155887976765],
			[-72.47941728503406, 41.275780154167215],
			[-72.84715167406202, 41.2658485131634],
			[-72.92471515358329, 41.28515149241539],
			[-73.0237239464227, 41.216475952686245],
			[-73.18226765364255, 41.17583752340162],
			[-73.63046591292746, 40.99186046560215],
			[-73.72301474458294, 41.104514278493376],
			[-73.48413900304868, 41.218958862937164],
			[-73.54472860496932, 41.29595105337422],
			[-73.48056844627186, 42.05556778157007],
			[-72.80769976826014, 42.03407852293778],
			[-72.8064583131347, 42.00802993795971],
			[-72.76332598727049, 42.011237945894656],
			[-72.75762408275617, 42.03407852293778],
			[-71.80163771816316, 42.02270767289465]
		], paths=[
			[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
		]);
	}
}

module feature1(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-69.97794013882904, 41.26559582760682],
			[-70.05509712419419, 41.24946789730411],
			[-70.23307564660854, 41.28633801589813],
			[-70.06269966354665, 41.32848157219326],
			[-70.0411994185859, 41.39747571545022],
			[-70.50989816693411, 41.376338019331364],
			[-70.78531443720604, 41.32744885731014],
			[-70.82918284708265, 41.35900159288877],
			[-70.7604853346964, 41.373602423523884],
			[-70.67371531185515, 41.44852918419462],
			[-70.61599314168438, 41.45720838374442],
			[-70.52535593119569, 41.41479016923571],
			[-70.7813373862731, 42.72124041438526],
			[-70.73567820484377, 42.66928606670026],
			[-70.62398020253602, 42.6717579906227],
			[-70.60413889318531, 42.64971941556323],
			[-70.61294992867772, 42.62326433642904],
			[-70.83117137254908, 42.55256731224781],
			[-70.93044383727351, 42.43198137014783],
			[-71.04617382215699, 42.33111588778451],
			[-70.99672435738003, 42.29998063269047],
			[-70.81794383298202, 42.26496720362052],
			[-70.73825999205161, 42.22886612802457],
			[-70.61769602260875, 42.04042862083623],
			[-70.64523874826875, 42.021565094726036],
			[-70.6561481725131, 41.987046050440476],
			[-70.54892160592277, 41.93862930054663],
			[-70.51467721985082, 41.80331069186902],
			[-70.42667672821258, 41.75729994792636],
			[-70.29546700641049, 41.72895522028259],
			[-70.13501167802397, 41.76985732145226],
			[-70.00140693659918, 41.82618422789783],
			[-70.00610908521605, 41.872326807783104],
			[-70.09003364896444, 41.97970718297305],
			[-70.11023750715702, 42.030145417319],
			[-70.17258492164473, 42.06280777208055],
			[-70.19622750067163, 42.03511123782091],
			[-70.24108468011721, 42.09122940402414],
			[-70.15985176686218, 42.09711807612377],
			[-70.10894112038878, 42.07830948165627],
			[-69.9778961935148, 41.96126113734753],
			[-69.9415863776766, 41.80785903188626],
			[-69.93384101605298, 41.710421284028776],
			[-69.94863960060187, 41.67714369486868],
			[-70.05951362826892, 41.67735243511101],
			[-70.40466012581021, 41.626892228107955],
			[-70.48135568537657, 41.58245252914714],
			[-70.65712595575351, 41.534233533167075],
			[-70.66645334868744, 41.71011366682951],
			[-70.70112620157263, 41.714848774431964],
			[-70.97424632917887, 41.548526746602924],
			[-71.07979198750195, 41.53808973448604],
			[-71.16853954948115, 41.489409312707174],
			[-71.18841381781743, 41.51640272193999],
			[-71.20427807623514, 41.641130509901096],
			[-71.14873119911621, 41.745720357640884],
			[-71.17833935454254, 41.74407240835931],
			[-71.23376538204744, 41.70655409638125],
			[-71.26788891850543, 41.75083998674243],
			[-71.3407282767528, 41.79791640455388],
			[-71.33763013210336, 41.891443019449774],
			[-71.37907056337164, 41.902407375336814],
			[-71.387134528523, 42.01686294610915],
			[-71.80083571617948, 42.0119630435785],
			[-71.80163771816316, 42.02270767289465],
			[-72.75762408275617, 42.03407852293778],
			[-72.76332598727049, 42.011237945894656],
			[-72.8064583131347, 42.00802993795971],
			[-72.80769976826014, 42.03407852293778],
			[-73.48056844627186, 42.05556778157007],
			[-73.50728719729108, 42.080012362580625],
			[-73.25332722666576, 42.75222186087965],
			[-71.32962109859469, 42.702486751560535],
			[-71.24233471831184, 42.72953509243606],
			[-71.13929394289678, 42.808131286840556],
			[-70.9234894913051, 42.881563906829264],
			[-70.80611155713996, 42.87676288125555],
			[-70.82905101114002, 42.825346863669104]
		], paths=[
			[0,1,2,3,4],
			[5,6,7,8,9,10,11],
			[12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77]
		]);
	}
}

module feature2(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-68.62319399339961, 44.1960671308017],
			[-68.66117373117649, 44.17626976676522],
			[-68.70171328350418, 44.182674796306465],
			[-68.70303164292946, 44.23200341146947],
			[-68.6767303723949, 44.25621727958066],
			[-68.1872564767699, 44.3324843723337],
			[-68.24544007273937, 44.313005611825055],
			[-68.30925965525208, 44.3215090301182],
			[-68.31510438203748, 44.24970238675403],
			[-68.41170716892572, 44.29435082595719],
			[-68.40948793055983, 44.36426782081187],
			[-68.34704163911519, 44.430361573333066],
			[-68.29943787753356, 44.45650903526808],
			[-68.23804627362915, 44.43840356582739],
			[-68.19089295151798, 44.36437768409727],
			[-68.93718326318984, 47.21125401340007],
			[-68.82871524147396, 47.20332188419132],
			[-68.37690248009801, 47.316151478339115],
			[-68.35801698133068, 47.344529164968556],
			[-68.23549744540699, 47.34594640135068],
			[-68.09679504753777, 47.27484288301333],
			[-67.80678893295928, 47.08281284639106],
			[-67.78464049461442, 45.9528030376596],
			[-67.76705138261525, 45.92698516558098],
			[-67.78228942030594, 45.87417388426953],
			[-67.77525817003777, 45.81787993680964],
			[-67.80069757575629, 45.75550276698336],
			[-67.86298828124998, 45.73959960937497],
			[-67.778955078125, 45.67011718750002],
			[-67.62548828125, 45.60224609375005],
			[-67.51240234374995, 45.58935546875001],
			[-67.43264951439019, 45.60310820010107],
			[-67.41386289257971, 45.56558988812301],
			[-67.42443174063919, 45.5304006777963],
			[-67.48778989735291, 45.50104520792643],
			[-67.49365659679552, 45.47407377135064],
			[-67.42794736577324, 45.37795438291834],
			[-67.47254087333377, 45.2758913907437],
			[-67.36694028336791, 45.17378445325493],
			[-67.31529355288208, 45.15383328061882],
			[-67.24958432185988, 45.20077786248775],
			[-67.12483456124167, 45.16944485348002],
			[-67.13037167082788, 45.139001737084335],
			[-67.10225765608357, 45.08773952809752],
			[-67.08044979392355, 44.98917018839999],
			[-67.11393612332597, 44.94438991325422],
			[-67.10672909180099, 44.88504176645902],
			[-67.0140154652174, 44.86774928533057],
			[-66.98702205598448, 44.827704117787356],
			[-67.19124691729078, 44.67556544010875],
			[-67.36407285161789, 44.69685694482717],
			[-67.45778623409902, 44.656526132741895],
			[-67.55600401128325, 44.64477076119966],
			[-67.59907041917609, 44.57678736016879],
			[-67.65299131967046, 44.56239526977601],
			[-67.7904852213999, 44.58567529996093],
			[-67.8390557798933, 44.57624903007015],
			[-67.90701720826704, 44.45361963086096],
			[-67.96269592132859, 44.464309328534306],
			[-67.9848883049876, 44.42018823310132],
			[-68.05661804405204, 44.38431787040482],
			[-68.1172845502725, 44.490643558054536],
			[-68.15203430745751, 44.502014408097686],
			[-68.19826477797108, 44.51524194766474],
			[-68.27743226145978, 44.50736475009868],
			[-68.37374940380585, 44.44513818522493],
			[-68.45059877197184, 44.50759546299805],
			[-68.52141664576703, 44.38024194251495],
			[-68.51447328612716, 44.303908931790566],
			[-68.53253481025371, 44.25864525818887],
			[-68.57234926489747, 44.2708400828728],
			[-68.6120318835988, 44.31052270157405],
			[-68.72329043276486, 44.34230615005222],
			[-68.81191714513, 44.339361814002395],
			[-68.79388857998913, 44.38173608319698],
			[-68.71011782484041, 44.44255639801708],
			[-68.79494326752939, 44.45449853714445],
			[-68.76551089335979, 44.50979272870689],
			[-68.76272036590953, 44.570766852126646],
			[-68.80021670523055, 44.54939844310841],
			[-68.84737002734184, 44.485040530497066],
			[-68.96147403560076, 44.43385522581007],
			[-68.956167638914, 44.348095945194906],
			[-69.06355900043252, 44.172347647475],
			[-69.06836002600633, 44.09756370907534],
			[-69.22605778592825, 43.98645896850892],
			[-69.34454533927632, 44.00092796320151],
			[-69.43495183686565, 43.956312482983954],
			[-69.48087469017995, 43.90507224665425],
			[-69.52073309013792, 43.89737083034486],
			[-69.55670232979128, 43.982767562118134],
			[-69.58997991895137, 43.88657126938602],
			[-69.62393866048117, 43.88062766564369],
			[-69.65287664986639, 43.99387474027616],
			[-69.69912909303696, 43.95501609621571],
			[-69.72984686764624, 43.851997293457764],
			[-69.76201483762338, 43.86070945199325],
			[-69.7722760684835, 43.899029765954985],
			[-69.79529242678339, 43.91063132889759],
			[-69.79160102039262, 43.80522849284558],
			[-69.8083441850938, 43.77231345252745],
			[-69.87252631644847, 43.81954367893845],
			[-69.97432563673797, 43.78787009374587],
			[-69.9652289567035, 43.85510642443568],
			[-70.0623590873619, 43.83463889435806],
			[-70.17881416992921, 43.766369848785125],
			[-70.26924264017566, 43.67190939596295],
			[-70.20257759857017, 43.62611837859118],
			[-70.52069772789295, 43.34882344613823],
			[-70.64232737120463, 43.1344252446002],
			[-70.73309641763592, 43.070034373003274],
			[-70.81283519020903, 43.16364887852746],
			[-70.82902903848301, 43.239070023982684],
			[-70.9196992079574, 43.32810323050405],
			[-70.95563548862515, 43.38939595745152],
			[-70.96754466876692, 43.45814840148048],
			[-71.08454906776151, 45.29400784651293],
			[-70.99987743367217, 45.33722806300542],
			[-70.96018382864239, 45.33309720347285],
			[-70.89799022275429, 45.26245511093432],
			[-70.86505320977906, 45.27069485734243],
			[-70.83682933174924, 45.31069607957141],
			[-70.83781810131822, 45.36617703871908],
			[-70.7991901701572, 45.4047720108945],
			[-70.71094797929106, 45.40947415951137],
			[-70.68978831051507, 45.42833768562158],
			[-70.70741038149981, 45.498924846517404],
			[-70.70221384809847, 45.55138456531544],
			[-70.59638254523321, 45.643988328613624],
			[-70.42109567331221, 45.73824004119347],
			[-70.40786813374507, 45.80190581510646],
			[-70.29624703573714, 45.90608916869012],
			[-70.28715035570258, 45.93915801760789],
			[-70.30643136229745, 45.9798294058781],
			[-70.30451974113075, 46.05739288539939],
			[-70.24829171164211, 46.25087311738944],
			[-70.17966011722712, 46.3418179450775],
			[-70.06721504457832, 46.44104646448772],
			[-70.00768013019788, 46.70893709970701],
			[-69.24287785492925, 47.46299474565951],
			[-69.05022159757996, 47.42661901184997],
			[-69.06428409811645, 47.33814610808444],
			[-69.0485736482984, 47.273656359530584],
			[-69.0030902481258, 47.23644566475169]
		], paths=[
			[0,1,2,3,4],
			[5,6,7,8,9,10,11,12,13,14],
			[15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143]
		]);
	}
}

module feature3(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-70.73309641763592, 43.070034373003274],
			[-70.80611155713996, 42.87676288125555],
			[-70.97408153425067, 42.87167621113958],
			[-71.13929394289678, 42.808131286840556],
			[-71.24233471831184, 42.72953509243606],
			[-71.32962109859469, 42.702486751560535],
			[-72.46685991150818, 42.73031512176271],
			[-72.55280595970865, 42.85644915977746],
			[-72.51941850726314, 42.96667499406039],
			[-72.47371538051965, 43.038536569067354],
			[-72.40707231157117, 43.33203633612283],
			[-72.38495683221188, 43.52922994716079],
			[-72.29669266868862, 43.71495383119868],
			[-72.22238114241642, 43.79086936143839],
			[-72.11492386292664, 43.96543113567555],
			[-72.06223343122906, 44.116350330885716],
			[-72.03120803942062, 44.30073388284131],
			[-72.00177566525102, 44.32949609096975],
			[-71.82551101008949, 44.37408959853028],
			[-71.68300734254402, 44.45027978698359],
			[-71.60928907801315, 44.51405542418198],
			[-71.56844190848625, 44.607636970720584],
			[-71.61828688109077, 44.72776148702176],
			[-71.62065992805628, 44.77189356878339],
			[-71.51022535353101, 44.90834376930106],
			[-71.53348341105891, 44.98797267858867],
			[-71.41901685395803, 45.20033840934597],
			[-71.32729199694333, 45.29010769987982],
			[-71.20161938472748, 45.26033474952529],
			[-71.13464672592261, 45.26281765977628],
			[-71.08454906776151, 45.29400784651293],
			[-70.96754466876692, 43.45814840148048],
			[-70.95563548862515, 43.38939595745152],
			[-70.9196992079574, 43.32810323050405],
			[-70.82902903848301, 43.239070023982684],
			[-70.81283519020903, 43.16364887852746]
		], paths=[
			[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35]
		]);
	}
}

module feature4(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-74.13322227976232, 39.680784976135534],
			[-74.2505013369705, 39.52937139614078],
			[-74.25316002847816, 39.55848516678264],
			[-74.10676720062813, 39.74643927551504],
			[-74.24151452022144, 40.45626596274898],
			[-74.04983604611266, 40.42983285627191],
			[-73.99845298751188, 40.45215707587352],
			[-73.97225059393426, 40.4003235778025],
			[-73.95759483165645, 40.3283631258387],
			[-74.02834678748039, 40.073007891488196],
			[-74.07991661366637, 39.7881104196828],
			[-74.06459068534741, 39.99311531031555],
			[-74.0959896123264, 39.97598762411538],
			[-74.11764366588679, 39.93812873595237],
			[-74.17613487905552, 39.72659796616433],
			[-74.25657677665546, 39.61385626264491],
			[-74.33060265838549, 39.535886288967426],
			[-74.40702355973826, 39.5488062113353],
			[-74.38987390088096, 39.48684331834658],
			[-74.42883142189828, 39.38718633212313],
			[-74.47435876738501, 39.342559865576995],
			[-74.51717248972136, 39.346844533709195],
			[-74.60298670197932, 39.29256108437284],
			[-74.60479944618908, 39.24752812367051],
			[-74.79447840850287, 39.001906776410245],
			[-74.92343593295348, 38.94114139323283],
			[-74.9543075161624, 38.94995242872516],
			[-74.89702479913342, 39.145465131495875],
			[-75.05021816435226, 39.21083378633323],
			[-75.13610928091003, 39.20786747762639],
			[-75.23103115953103, 39.284266406322025],
			[-75.35342984584076, 39.339824269769515],
			[-75.52424528204435, 39.490172175895474],
			[-75.5235531433461, 39.6018482055462],
			[-75.42190763165613, 39.78971442365022],
			[-75.3531771602843, 39.82973761853632],
			[-75.15383022885172, 39.87048591110635],
			[-75.07416836057843, 39.98348030018244],
			[-74.90929652811727, 40.07954475697195],
			[-74.73488856247965, 40.154504476628354],
			[-74.97637905020744, 40.40582772840305],
			[-75.0340462887354, 40.420373627395456],
			[-75.09744839076345, 40.54313486254717],
			[-75.18901943917842, 40.59581430791609],
			[-75.19228237875606, 40.689868266582074],
			[-75.17473721207114, 40.775517683911836],
			[-75.11179653584199, 40.80210459898854],
			[-75.07556362430353, 40.85626719871093],
			[-75.12303554994253, 40.99900157915588],
			[-75.03154140582737, 41.05177990148166],
			[-74.9122957958098, 41.155271116367054],
			[-74.8124850009867, 41.30151013561747],
			[-74.69905115876884, 41.35729871196441],
			[-73.9100789607032, 40.992255973429785],
			[-73.92721763323203, 40.91424205443817],
			[-74.02550132838749, 40.75637949958803],
			[-74.226704949344, 40.608009132600024],
			[-74.26419030233646, 40.52863290886899]
		], paths=[
			[0,1,2,3],
			[4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57]
		]);
	}
}

module feature5(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-74.18813194982567, 40.522854100054765],
			[-74.23587853367837, 40.51871225419364],
			[-74.1881539224828, 40.614600929726485],
			[-74.10048302070095, 40.65844736694597],
			[-74.06875450386556, 40.64930674159725],
			[-74.07970787342404, 40.586464942325044],
			[-72.50978349712994, 40.9860267251453],
			[-72.58088701546737, 40.921328236349105],
			[-72.51657304817016, 40.914813343522475],
			[-72.28744218005451, 41.02408336722201],
			[-72.18385208821226, 41.04679210832263],
			[-72.1512446650934, 41.051472284282475],
			[-72.10189407727327, 41.01501964617311],
			[-71.90320632555338, 41.060700800259475],
			[-72.55554155551613, 40.82578013700111],
			[-73.19428669706983, 40.654206644128],
			[-73.26552205134968, 40.663566996047514],
			[-73.62089682076552, 40.59990122213453],
			[-73.89956504428653, 40.57052377960755],
			[-73.80132529444518, 40.62178598859436],
			[-73.79918296037914, 40.64097910456086],
			[-73.8226717308064, 40.65596445669505],
			[-73.87517539491867, 40.65162485692016],
			[-73.9289974184561, 40.59881357560861],
			[-74.014910507671, 40.58121347728099],
			[-74.03203819387124, 40.638682961895164],
			[-73.9645711502819, 40.72534312145101],
			[-73.879262309137, 40.791667586871675],
			[-73.6952083470378, 40.870033068376706],
			[-73.6522408161018, 40.838018906999274],
			[-73.64283651886805, 40.8812281371631],
			[-73.57379843029705, 40.91962535542475],
			[-73.37270467262587, 40.94380626455037],
			[-73.2781563291754, 40.92419566809911],
			[-73.18583821041938, 40.92985362729929],
			[-73.0337764370405, 40.96597667555226],
			[-72.62511797418586, 40.991838492945114],
			[-72.37257523994273, 41.125553097655306],
			[-72.27413773618764, 41.153040891672624],
			[-78.92993164062497, 43.02246093750002],
			[-78.96054687499998, 42.98823242187506],
			[-79.01201171874999, 43.00268554687498],
			[-79.01943359375, 43.024218750000024],
			[-79.01416015624997, 43.05151367187498],
			[-78.98798828124998, 43.06352539062504],
			[-78.91621093750001, 43.05317382812506],
			[-76.26201171875002, 43.99013671874999],
			[-76.27666015624996, 43.98706054687498],
			[-76.27514648437503, 44.00859375000001],
			[-76.23056640625, 44.02851562499999],
			[-76.11123046875002, 44.27729492187505],
			[-76.14272460937494, 44.269238281250004],
			[-76.15029296875, 44.28105468750001],
			[-76.11914062500003, 44.305859375000004],
			[-76.075439453125, 44.305761718749984],
			[-73.35218221090554, 45.00541896831667],
			[-73.34505208368037, 44.93886378999657],
			[-73.36580525830024, 44.86036647254901],
			[-73.3485677088145, 44.775299330632016],
			[-73.37207845189886, 44.59733179454623],
			[-73.30975301006816, 44.459640138903104],
			[-73.32091511986897, 44.26887353006341],
			[-73.38112020029064, 44.187431876566045],
			[-73.42613118833586, 44.07485496797472],
			[-73.37496785630597, 43.80415183264822],
			[-73.41592488911834, 43.58964376782479],
			[-73.39143636279354, 43.57852560333813],
			[-73.33048421203094, 43.6266896676754],
			[-73.24709797838128, 43.55304830744435],
			[-73.26655476623282, 42.864776796813864],
			[-73.28019978628461, 42.81315203898517],
			[-73.25332722666576, 42.75222186087965],
			[-73.50728719729108, 42.080012362580625],
			[-73.48056844627186, 42.05556778157007],
			[-73.54472860496932, 41.29595105337422],
			[-73.48413900304868, 41.218958862937164],
			[-73.72301474458294, 41.104514278493376],
			[-73.63046591292746, 40.99186046560215],
			[-73.77900107484356, 40.87840465072734],
			[-73.85124717134963, 40.831405137215704],
			[-73.91067222244453, 40.816112167882316],
			[-73.98708213746883, 40.75139170642901],
			[-73.90675010315431, 40.91246226921398],
			[-73.87196738698373, 41.05516369067326],
			[-73.88225059050106, 41.17058605835755],
			[-73.92532798472246, 41.21805798399655],
			[-73.96995445126848, 41.24973156918923],
			[-73.9176485410701, 41.135781369529845],
			[-73.9100789607032, 40.992255973429785],
			[-74.69905115876884, 41.35729871196441],
			[-74.75661952033994, 41.423908821927306],
			[-74.93536708575238, 41.47436902893036],
			[-75.02273037033495, 41.55286634637792],
			[-75.05136074252087, 41.608369278182614],
			[-75.06690639741083, 41.71321181147895],
			[-75.05367885784369, 41.76504530954998],
			[-75.09476772659858, 41.799487449535725],
			[-75.09553676959666, 41.831710351155586],
			[-75.23886441178294, 41.8922010761193],
			[-75.27397671780992, 41.94666030671241],
			[-75.35134244341742, 41.998416900483626],
			[-79.76295760194162, 42.00089981073463],
			[-79.76300290720809, 42.275685276580525],
			[-79.51225585937493, 42.39101562499999],
			[-79.41635742187495, 42.456884765624984],
			[-79.20922851562503, 42.555175781250036],
			[-78.99360351562498, 42.73071289062499],
			[-78.87783203125002, 42.799121093749996],
			[-78.87226562500004, 42.835937500000036],
			[-78.91972656250002, 42.94819335937499],
			[-78.92431640624997, 42.99750976562499],
			[-78.89472656249998, 43.057763671875016],
			[-79.06605083707547, 43.106102489613455],
			[-79.06139356384946, 43.28291031482525],
			[-78.689453125, 43.36147460937499],
			[-78.45747070312498, 43.387548828125055],
			[-78.174951171875, 43.394677734375],
			[-77.83823242187495, 43.35708007812497],
			[-77.70737304687495, 43.32285156250001],
			[-77.62460937499995, 43.27910156249998],
			[-77.52905273437503, 43.267382812499996],
			[-77.27080078124999, 43.29453125000003],
			[-77.07900390625, 43.287695312500055],
			[-76.97641601562498, 43.277392578124996],
			[-76.96308593750001, 43.26376953124997],
			[-76.88530273437499, 43.314013671874996],
			[-76.74140624999998, 43.35004882812505],
			[-76.722314453125, 43.342626953125055],
			[-76.57968749999998, 43.45380859375005],
			[-76.47270507812493, 43.50727539062502],
			[-76.37602539062496, 43.53505859375],
			[-76.23178710937498, 43.550439453125016],
			[-76.20258789062498, 43.57451171875004],
			[-76.19501953125004, 43.64482421874998],
			[-76.21811523437495, 43.75781249999999],
			[-76.25820312499994, 43.829101562500036],
			[-76.28818359375, 43.84873046875004],
			[-76.28461914062498, 43.86923828125004],
			[-76.23251953124995, 43.89453125000005],
			[-76.23642578124995, 43.87094726562504],
			[-76.19833984375, 43.87446289062505],
			[-76.07065429687492, 43.99848632812499],
			[-76.19228515625002, 44.00336914062502],
			[-76.15415039062498, 44.045410156249964],
			[-76.17329101562495, 44.07944335937497],
			[-76.19760742187495, 44.08349609374999],
			[-76.3060546875, 44.04321289062505],
			[-76.35244140624997, 44.10605468749997],
			[-76.23779296874994, 44.18320312499997],
			[-75.83217773437502, 44.39726562499997],
			[-75.77568359374996, 44.45888671875],
			[-75.79196013600688, 44.49704858759578],
			[-75.40125333399328, 44.77227809028239],
			[-75.17938442904523, 44.8993789252091],
			[-74.99614345525825, 44.970119894704474],
			[-74.85663905540537, 45.00392482763464]
		], paths=[
			[0,1,2,3,4,5],
			[6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38],
			[39,40,41,42,43,44,45],
			[46,47,48,49],
			[50,51,52,53,54],
			[55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155]
		]);
	}
}

module feature6(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-74.69905115876884, 41.35729871196441],
			[-74.8124850009867, 41.30151013561747],
			[-74.9122957958098, 41.155271116367054],
			[-75.03154140582737, 41.05177990148166],
			[-75.12303554994253, 40.99900157915588],
			[-75.07556362430353, 40.85626719871093],
			[-75.11179653584199, 40.80210459898854],
			[-75.17473721207114, 40.775517683911836],
			[-75.19228237875606, 40.689868266582074],
			[-75.18901943917842, 40.59581430791609],
			[-75.09744839076345, 40.54313486254717],
			[-75.0340462887354, 40.420373627395456],
			[-74.97637905020744, 40.40582772840305],
			[-74.73488856247965, 40.154504476628354],
			[-75.02353237231873, 40.017450028040706],
			[-75.1729244678613, 39.89477668351737],
			[-75.32087735436463, 39.86469611596366],
			[-75.42102872537265, 39.81542243244336],
			[-75.510446453393, 39.843437570230826],
			[-75.63458097961268, 39.83948249195492],
			[-75.70914519144145, 39.802898017903125],
			[-75.78472014549632, 39.72235724334636],
			[-80.51944322650235, 39.72251105194599],
			[-80.52027818747169, 41.98956770933888],
			[-80.33447265625003, 42.04082031250005],
			[-79.76300290720809, 42.275685276580525],
			[-79.76295760194162, 42.00089981073463],
			[-75.35134244341742, 41.998416900483626],
			[-75.27397671780992, 41.94666030671241],
			[-75.23886441178294, 41.8922010761193],
			[-75.09553676959666, 41.831710351155586],
			[-75.09476772659858, 41.799487449535725],
			[-75.05367885784369, 41.76504530954998],
			[-75.06690639741083, 41.71321181147895],
			[-75.05136074252087, 41.608369278182614],
			[-74.98125698008107, 41.50770154973306],
			[-74.93536708575238, 41.47436902893036],
			[-74.75661952033994, 41.423908821927306]
		], paths=[
			[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37]
		]);
	}
}

module feature7(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-71.36535962534859, 41.48526746684605],
			[-71.39307813226534, 41.46674451692069],
			[-71.40338330843969, 41.515040417200574],
			[-71.38398145223087, 41.57053236267681],
			[-71.36431592413692, 41.571806776787845],
			[-71.35447217376145, 41.54229749831844],
			[-71.24137890772852, 41.491969127257896],
			[-71.29093823579089, 41.46460218285464],
			[-71.34623242735336, 41.46940320842835],
			[-71.31815137159461, 41.50630628600798],
			[-71.28019360647485, 41.62004774542502],
			[-71.23205151479459, 41.65430311782554],
			[-71.3407282767528, 41.79791640455388],
			[-71.26788891850543, 41.75083998674243],
			[-71.23376538204744, 41.70655409638125],
			[-71.27107495378326, 41.6812306090871],
			[-71.3305988818351, 41.76225478209981],
			[-71.39015576887266, 41.795334617346036],
			[-71.36367871708134, 41.70273085404785],
			[-71.42654248901067, 41.6332972576492],
			[-71.44380201115345, 41.45369275861031],
			[-71.52285963135674, 41.3789747381819],
			[-71.76928298060085, 41.33090955080147],
			[-71.84235305174761, 41.3355128224615],
			[-71.82987258252152, 41.39274060784768],
			[-71.80452712257028, 41.41674573571654],
			[-71.79579299137777, 41.51995130605979],
			[-71.80083571617948, 42.0119630435785],
			[-71.387134528523, 42.01686294610915],
			[-71.37907056337164, 41.902407375336814],
			[-71.33763013210336, 41.891443019449774]
		], paths=[
			[0,1,2,3,4,5],
			[6,7,8,9,10,11],
			[12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
		]);
	}
}

module feature8(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=[
			[-72.46685991150818, 42.73031512176271],
			[-73.25332722666576, 42.75222186087965],
			[-73.28019978628461, 42.81315203898517],
			[-73.26655476623282, 42.864776796813864],
			[-73.24709797838128, 43.55304830744435],
			[-73.33048421203094, 43.6266896676754],
			[-73.39143636279354, 43.57852560333813],
			[-73.41592488911834, 43.58964376782479],
			[-73.37496785630597, 43.80415183264822],
			[-73.42613118833586, 44.07485496797472],
			[-73.38112020029064, 44.187431876566045],
			[-73.32091511986897, 44.26887353006341],
			[-73.30975301006816, 44.459640138903104],
			[-73.37207845189886, 44.59733179454623],
			[-73.3485677088145, 44.775299330632016],
			[-73.36580525830024, 44.86036647254901],
			[-73.34505208368037, 44.93886378999657],
			[-73.35218221090554, 45.00541896831667],
			[-71.51752027568429, 45.00756130238272],
			[-71.53348341105891, 44.98797267858867],
			[-71.51022535353101, 44.90834376930106],
			[-71.62065992805628, 44.77189356878339],
			[-71.61828688109077, 44.72776148702176],
			[-71.56844190848625, 44.607636970720584],
			[-71.60928907801315, 44.51405542418198],
			[-71.68300734254402, 44.45027978698359],
			[-71.82551101008949, 44.37408959853028],
			[-72.00177566525102, 44.32949609096975],
			[-72.03120803942062, 44.30073388284131],
			[-72.06223343122906, 44.116350330885716],
			[-72.11492386292664, 43.96543113567555],
			[-72.22238114241642, 43.79086936143839],
			[-72.29669266868862, 43.71495383119868],
			[-72.36236894072525, 43.58664450013219],
			[-72.38495683221188, 43.52922994716079],
			[-72.40707231157117, 43.33203633612283],
			[-72.47371538051965, 43.038536569067354],
			[-72.54980669201612, 42.88668353593081],
			[-72.53962236545573, 42.829631531801304]
		], paths=[
			[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38]
		]);
	}
}

module Prismap() {
	union() {
		if (wall_thickness > 0) {
			Walls();
		}
		scale([xy_scale, xy_scale, 1]) translate([73.7537, -43.2021, 0]) {
			if (floor_thickness > 0 || wall_thickness > 0) {
				Floor();
			}
			feature0(extrusionheight(data0));
			feature1(extrusionheight(data1));
			feature2(extrusionheight(data2));
			feature3(extrusionheight(data3));
			feature4(extrusionheight(data4));
			feature5(extrusionheight(data5));
			feature6(extrusionheight(data6));
			feature7(extrusionheight(data7));
			feature8(extrusionheight(data8));
		}
	}
}
