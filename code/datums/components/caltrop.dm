/datum/component/caltrop
	var/min_damage
	var/max_damage
	var/probability
	var/flags
	COOLDOWN_DECLARE(caltrop_cooldown)


/datum/component/caltrop/Initialize(_min_damage = 0, _max_damage = 0, _probability = 100,  _flags = NONE)
	min_damage = _min_damage
	max_damage = max(_min_damage, _max_damage)
	probability = _probability
	flags = _flags

	RegisterSignal(parent, list(COMSIG_MOVABLE_CROSSED), .proc/Crossed)

/datum/component/caltrop/proc/Crossed(datum/source, atom/movable/AM)
	SIGNAL_HANDLER

	if(!prob(probability))
		return

	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(HAS_TRAIT(H, TRAIT_PIERCEIMMUNE))
			return

		if((flags & CALTROP_IGNORE_WALKERS) && H.m_intent == MOVE_INTENT_WALK)
			return

		//move these next two down a level if you add more mobs to this.
		if(H.is_flying() || H.is_floating()) //check if they are able to pass over us
			return							//gravity checking only our parent would prevent us from triggering they're using magboots / other gravity assisting items that would cause them to still touch us.
		if(H.buckled) //if they're buckled to something, that something should be checked instead.
			return
		if(H.body_position == LYING_DOWN) //if were not standing we cant step on the caltrop
			return

		var/picked_def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		var/obj/item/bodypart/O = H.get_bodypart(picked_def_zone)
		if(!istype(O))
			return
		if(O.status == BODYPART_ROBOTIC)
			return

		if (!(flags & CALTROP_BYPASS_SHOES))
			if ((H.wear_suit?.body_parts_covered | H.w_uniform?.body_parts_covered | H.shoes?.body_parts_covered) & FEET)
				return

		var/damage = rand(min_damage, max_damage)
		if(HAS_TRAIT(H, TRAIT_LIGHT_STEP))
			damage *= 0.75


		if(!(flags & CALTROP_SILENT) && COOLDOWN_FINISHED(src, caltrop_cooldown))
			COOLDOWN_START(src, caltrop_cooldown, 1 SECONDS) //cooldown to avoid message spam.
			var/atom/A = parent
			if(!H.incapacitated(ignore_restraints = TRUE))
				H.visible_message("<span class='danger'>[H] steps on [A].</span>", \
						"<span class='userdanger'>You step on [A]!</span>")
			else
				H.visible_message("<span class='danger'>[H] slides on [A]!</span>", \
						"<span class='userdanger'>You slide on [A]!</span>")

		H.apply_damage(damage, BRUTE, picked_def_zone, wound_bonus = CANT_WOUND)
		H.Paralyze(60)
