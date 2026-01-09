extends MeshInstance3D
class_name DebugLine

@export var m_pntStart : Vector3 = Vector3.ZERO : get=getStart,set=setStart
@export var m_pntEnd : Vector3 = Vector3.ZERO : get=getEnd,set=setEnd

var m_color : Color = Color.REBECCA_PURPLE
var m_material : ORMMaterial3D = ORMMaterial3D.new()

func _ready():
	mesh = ImmediateMesh.new()
	m_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _process(delta):
	draw()

func getStart():
	return m_pntStart

func getEnd():
	return m_pntEnd
	
func setStart(a : Vector3):
	m_pntStart = a
	
func setEnd(a : Vector3):
	m_pntEnd = a

func setColor(a):
	m_color = a
	m_material.albedo_color = m_color

func draw():
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, m_material)
	mesh.surface_add_vertex(m_pntStart)
	mesh.surface_add_vertex(m_pntEnd)
	mesh.surface_end()