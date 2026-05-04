extends CSGBox3D

# O variabilă pe care o poți modifica direct din meniul (Inspectorul) din Godot
@export var interact_message: String = "Apasă E pentru a interacționa"

# Această funcție este apelată de raza laser (RayCast3D) a jucătorului!
func interact():
	print("Succes! Ai interacționat cu: " + name)
	
	# Exemplu vizual simplu: Când dai click pe el, obiectul sare puțin în sus
	position.y += 0.5
	
	# Așteptăm jumătate de secundă...
	await get_tree().create_timer(0.5).timeout
	
	# ...și îl punem la loc
	position.y -= 0.5
