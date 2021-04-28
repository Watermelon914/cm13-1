

//Supply drop. Just docks and has a crapload of stuff inside.
/datum/emergency_call/supplies
	name = "Supply Drop"
	mob_max = 0
	mob_min = 0
	arrival_message = "Weyland-Yutani Automated Supply Drop 334-Q signal received. Docking procedures have commenced."
	probability = 0
	auto_shuttle_launch = TRUE

/datum/emergency_call/supplies/spawn_items()
	var/turf/drop_spawn
	var/list/choices = list(0,1,2,3,4,5,6)

	for(var/i = 1 to 4) //Spawns 4 random things.
		drop_spawn = get_spawn_point(TRUE)
		if(istype(drop_spawn))
			var/obj/structure/closet/crate/weapon/W = new(drop_spawn)
			switch(pick_n_take(choices))
				if(0)
					new /obj/item/weapon/gun/pistol/m4a3(W)
					new /obj/item/weapon/gun/pistol/m1911(W)
					new /obj/item/attachable/quickfire(W)
					new /obj/item/attachable/burstfire_assembly(W)
					new /obj/item/attachable/compensator(W)
					new /obj/item/attachable/extended_barrel(W)

				if(1)
					new /obj/item/weapon/gun/smg/m39(W)
					new /obj/item/weapon/gun/smg/m39(W)
					new /obj/item/ammo_magazine/smg/m39/extended(W)
					new /obj/item/ammo_magazine/smg/m39/extended(W)
					new /obj/item/ammo_magazine/smg/m39/ap(W)
					new /obj/item/ammo_magazine/smg/m39/ap(W)
					new /obj/item/ammo_magazine/smg/m39/ap(W)
					new /obj/item/attachable/stock/smg(W)
					new /obj/item/attachable/stock/smg(W)
					new /obj/item/attachable/verticalgrip(W)
					new /obj/item/attachable/verticalgrip(W)
				if(2)
					new /obj/item/weapon/gun/flamer(W)
					new /obj/item/weapon/gun/flamer(W)
					new /obj/item/ammo_magazine/flamer_tank(W)
					new /obj/item/ammo_magazine/flamer_tank(W)
				if(3)
					new /obj/item/explosive/plastic(W)
					new /obj/item/explosive/plastic(W)
					new /obj/item/explosive/plastic(W)
					new /obj/item/explosive/grenade/HE/PMC(W)
					new /obj/item/explosive/grenade/HE/PMC(W)
					new /obj/item/explosive/grenade/incendiary(W)
					new /obj/item/explosive/grenade/incendiary(W)
				if(4)
					new /obj/item/weapon/gun/rifle/m41a(W)
					new /obj/item/weapon/gun/rifle/m41a(W)
					new /obj/item/ammo_magazine/rifle/extended(W)
					new /obj/item/ammo_magazine/rifle/extended(W)
					new /obj/item/ammo_magazine/rifle/incendiary(W)
					new /obj/item/ammo_magazine/rifle/incendiary(W)
					new /obj/item/ammo_magazine/rifle/l42a/incendiary(W)
					new /obj/item/ammo_magazine/rifle/l42a/incendiary(W)
					new /obj/item/ammo_magazine/rifle/ap(W)
					new /obj/item/ammo_magazine/rifle/ap(W)
					new /obj/item/attachable/stock/rifle(W)
					new /obj/item/attachable/stock/rifle(W)
				if(5)
					new /obj/item/weapon/gun/shotgun/combat(W)
					new /obj/item/weapon/gun/shotgun/combat(W)
					new /obj/item/ammo_magazine/shotgun/incendiary(W)
					new /obj/item/ammo_magazine/shotgun/incendiary(W)
					new /obj/item/ammo_magazine/shotgun/flechette(W)
					new /obj/item/ammo_magazine/shotgun/flechette(W)
					new /obj/item/attachable/stock/tactical(W)
					new /obj/item/attachable/stock/tactical(W)
				if(6)
					new /obj/item/weapon/gun/rifle/lmg(W)
					new /obj/item/ammo_magazine/rifle/lmg(W)
					new /obj/item/ammo_magazine/rifle/lmg(W)
					new /obj/item/attachable/verticalgrip (W)
				if(7)
					new /obj/item/weapon/gun/rifle/l42a(W)
					new /obj/item/weapon/gun/rifle/l42a(W)
					new /obj/item/ammo_magazine/rifle/l42a/incendiary(W)
					new /obj/item/ammo_magazine/rifle/l42a/incendiary(W)
					new /obj/item/ammo_magazine/rifle/l42a/ap(W)
					new /obj/item/ammo_magazine/rifle/l42a/ap(W)
					new /obj/item/attachable/stock/carbine(W)
					new /obj/item/attachable/stock/carbine(W)
					new /obj/item/attachable/scope/mini_iff(W)
					new /obj/item/attachable/scope/mini_iff(W)
