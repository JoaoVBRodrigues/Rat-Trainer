extends GdUnitTestSuite

## Independent MVP fixtures: each of the fifteen outcomes must win its priority check.
func test_all_fifteen_ending_routes_select_the_expected_outcome() -> void:
	var routes: Dictionary = {
		"evadida_do_sistema": {"flags": {"disappear_from_society": true}},
		"aprendiz_de_ciborgues": {"stats": {"int": 70, "ref": 50}, "flags": {"tech_experiments": true}},
		"tecnica_juvenil_da_cidade": {"stats": {"int": 65}, "missions": 5},
		"guardia_da_rede": {"stats": {"eth": 65}, "reps": {"hacker": 70}, "flags": {"community_help": true}},
		"lider_comunitaria_jovem": {"stats": {"cha": 75}, "reps": {"social": 75}, "flags": {"community_help": true}},
		"promessa_corporativa": {"stats": {"cha": 60, "eth": 30}, "reps": {"social": 70}},
		"recruta_do_submundo": {"stats": {"int": 50, "eth": 35}, "flags": {"criminal_record": true}},
		"voz_das_ruas": {"stats": {"cha": 65}, "reps": {"social": 65}, "flags": {"community_help": true}},
		"mediadora_comunitaria": {"stats": {"eth": 70, "cha": 55}, "flags": {"community_help": true}},
		"autora_emergente": {"stats": {"int": 55, "ref": 55}},
		"mecanica_de_campo": {"stats": {"str": 50, "int": 55}, "missions": 3},
		"defensora_das_ruas": {"stats": {"str": 60}, "reps": {"fighter": 70}},
		"hacker_de_elite": {"stats": {"int": 65}, "reps": {"hacker": 70}},
		"artista_emergente": {"stats": {"ref": 60}, "reps": {"social": 65}},
		"caminho_equilibrado": {}
	}
	var evaluator: EndingEvaluator = EndingEvaluator.new()
	assert_bool(evaluator.load_endings("res://assets/data/endings.json")).is_true()
	for expected: String in routes:
		var fixture: Dictionary = routes[expected]
		var simulation: SimulationCore = SimulationCore.new()
		assert_bool(simulation.initialize()).is_true()
		var stats: Dictionary = fixture.get("stats", {})
		for id: String in stats:
			simulation.stats.add_stat(id, int(stats[id]) - simulation.stats.get_stat(id))
		var reps: Dictionary = fixture.get("reps", {})
		for id: String in reps:
			simulation.stats.add_reputation(id, int(reps[id]))
		var state: CharacterState = CharacterState.new()
		var flags: Dictionary = fixture.get("flags", {})
		for id: String in flags:
			state.set(id, flags[id])
		var ending: EndingDef = evaluator.evaluate(state, simulation.stats, simulation.activities, int(fixture.get("missions", 0)))
		assert_object(ending).is_not_null()
		if ending != null:
			assert_str(ending.id).is_equal(expected)
