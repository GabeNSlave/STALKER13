
/*

Contents:
- The Ninja Space Suit
- Ninja Space Suit Procs

*/


// /obj/item/clothing/suit/space/space_ninja


/obj/item/clothing/suit/space/space_ninja
	name = "ninja suit"
	desc = "A unique, vaccum-proof suit of nano-enhanced armor designed specifically for Spider Clan assassins."
	icon_state = "s-ninja"
	item_state = "s-ninja_suit"
	allowed = list(/obj/item/weapon/gun,/obj/item/ammo_box,/obj/item/ammo_casing,/obj/item/weapon/melee/baton,/obj/item/weapon/restraints/handcuffs,/obj/item/weapon/tank/internals,/obj/item/weapon/stock_parts/cell)
	slowdown = 0
	unacidable = 1
	armor = list(melee = 60, bullet = 50, laser = 30,energy = 15, bomb = 30, bio = 30, rad = 30)
	strip_delay = 12

		//Important parts of the suit.
	var/mob/living/carbon/human/affecting = null
	var/obj/item/weapon/stock_parts/cell/cell
	var/datum/effect_system/spark_spread/spark_system
	var/list/reagent_list = list("omnizine","salbutamol","spaceacillin","charcoal","nutriment","radium","potass_iodide")//The reagents ids which are added to the suit at New().
	var/list/stored_research = list()//For stealing station research.
	var/obj/item/weapon/disk/tech_disk/t_disk//To copy design onto disk.
	var/obj/item/weapon/katana/energy/energyKatana //For teleporting the katana back to the ninja (It's an ability)

		//Other articles of ninja gear worn together, used to easily reference them after initializing.
	var/obj/item/clothing/head/helmet/space/space_ninja/n_hood
	var/obj/item/clothing/shoes/space_ninja/n_shoes
	var/obj/item/clothing/gloves/space_ninja/n_gloves

		//Main function variables.
	var/s_initialized = 0//Suit starts off.
	var/s_coold = 0//If the suit is on cooldown. Can be used to attach different cooldowns to abilities. Ticks down every second based on suit ntick().
	var/s_cost = 5//Base energy cost each ntick.
	var/s_acost = 25//Additional cost for additional powers active.
	var/s_delay = 40//How fast the suit does certain things, lower is faster. Can be overridden in specific procs. Also determines adverse probability.
	var/a_transfer = 20//How much reagent is transferred when injecting.
	var/r_maxamount = 80//How much reagent in total there is.

		//Support function variables.
	var/spideros = 0//Mode of SpiderOS. This can change so I won't bother listing the modes here (0 is hub). Check ninja_equipment.dm for how it all works.
	var/s_active = 0//Stealth off.
	var/s_busy = 0//Is the suit busy with a process? Like AI hacking. Used for safety functions.

		//Ability function variables.
	var/s_bombs = 10//Number of starting ninja smoke bombs.
	var/a_boost = 3//Number of adrenaline boosters.


/obj/item/clothing/suit/space/space_ninja/New()
	..()
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/init//suit initialize verb

	//Spark Init
	spark_system = new()
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

	//Research Init
	stored_research = new()
	for(var/T in subtypesof(/datum/tech))//Store up on research.
		stored_research += new T(src)

	//Reagent Init
	var/reagent_amount
	for(var/reagent_id in reagent_list)
		reagent_amount += reagent_id == "radium" ? r_maxamount+(a_boost*a_transfer) : r_maxamount
	reagents = new(reagent_amount)
	reagents.my_atom = src
	for(var/reagent_id in reagent_list)
		reagent_id == "radium" ? reagents.add_reagent(reagent_id, r_maxamount+(a_boost*a_transfer)) : reagents.add_reagent(reagent_id, r_maxamount)//It will take into account radium used for adrenaline boosting.

	//Cell Init
	cell = new/obj/item/weapon/stock_parts/cell/high
	cell.charge = 9000
	cell.name = "black power cell"
	cell.icon_state = "bscell"


/obj/item/clothing/suit/space/space_ninja/Destroy()
	if(affecting)
		affecting << browse(null, "window=hack spideros")
	return ..()


//Simply deletes all the attachments and self, killing all related procs.
/obj/item/clothing/suit/space/space_ninja/proc/terminate()
	qdel(n_hood)
	qdel(n_gloves)
	qdel(n_shoes)
	qdel(src)


//Randomizes suit parameters.
/obj/item/clothing/suit/space/space_ninja/proc/randomize_param()
	s_cost = rand(1,20)
	s_acost = rand(20,100)
	s_delay = rand(10,100)
	s_bombs = rand(5,20)
	a_boost = rand(1,7)


//This proc prevents the suit from being taken off.
/obj/item/clothing/suit/space/space_ninja/proc/lock_suit(mob/living/carbon/human/H, checkIcons = 0)
	if(!istype(H))
		return 0
	if(checkIcons)
		icon_state = H.gender==FEMALE ? "s-ninjanf" : "s-ninjan"
		H.gloves.icon_state = "s-ninjan"
		H.gloves.item_state = "s-ninjan"
	else
		if(H.mind.special_role!="Space Ninja")
			H << "\red <B>FATAL ERROR/B>: 382200-*#00CODE <B>RED</B>\nUNAUHORIZED USE DETECeD\nCoMMENCING SUB-R0UIN3 13...\nTERMInATING U-U-USER..."
			H.gib()
			return 0
		if(!istype(H.head, /obj/item/clothing/head/helmet/space/space_ninja))
			H << "<span class='userdanger'>ERROR</span>: 100113 UNABLE TO LOCATE HEAD GEAR\nABORTING..."
			return 0
		if(!istype(H.shoes, /obj/item/clothing/shoes/space_ninja))
			H << "<span class='userdanger'>ERROR</span>: 122011 UNABLE TO LOCATE FOOT GEAR\nABORTING..."
			return 0
		if(!istype(H.gloves, /obj/item/clothing/gloves/space_ninja))
			H << "<span class='userdanger'>ERROR</span>: 110223 UNABLE TO LOCATE HAND GEAR\nABORTING..."
			return 0

		affecting = H
		flags |= NODROP //colons make me go all |=
		slowdown = 0
		n_hood = H.head
		n_hood.flags |= NODROP
		n_shoes = H.shoes
		n_shoes.flags |= NODROP
		n_shoes.slowdown--
		n_gloves = H.gloves
		n_gloves.flags |= NODROP

	return 1


//This proc allows the suit to be taken off.
/obj/item/clothing/suit/space/space_ninja/proc/unlock_suit()
	affecting = null
	flags &= ~NODROP
	slowdown = 1
	icon_state = "s-ninja"
	if(n_hood)//Should be attached, might not be attached.
		n_hood.flags &= ~NODROP
	if(n_shoes)
		n_shoes.flags &= ~NODROP
		n_shoes.slowdown++
	if(n_gloves)
		n_gloves.icon_state = "s-ninja"
		n_gloves.item_state = "s-ninja"
		n_gloves.flags &= ~NODROP
		n_gloves.candrain=0
		n_gloves.draining=0


/obj/item/clothing/suit/space/space_ninja/examine(mob/user)
	..()
	if(s_initialized)
		if(user == affecting)
			user << "All systems operational. Current energy capacity: <B>[cell.charge]</B>."
			user << "The CLOAK-tech device is <B>[s_active?"active":"inactive"]</B>."
			user << "There are <B>[s_bombs]</B> smoke bomb\s remaining."
			user << "There are <B>[a_boost]</B> adrenaline booster\s remaining."
