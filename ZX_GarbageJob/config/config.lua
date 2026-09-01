Config = {}

Config.Settings = {
    Interaction = {
        type = "textUi", -- qb-target, textUi, ox_target
        targetIconBoss = "fa-solid fa-hand",
        targetIconGarbage = "fa-solid fa-trash",
        distance = 3.0
    }
}

Config.GarbageStation = {
    Boss = {
        distance = 15.0,
        coords = vector3(-322.500, -1545.910, 30.142),
        heading = 270.7747,
        model = "S_M_Y_Garbage",
        animations = {
            dict = "amb@world_human_leaning@male@wall@back@foot_up@idle_a",
            name = "idle_a"
        },
        blip = {
            sprite = 318,
            scale = 0.6,
            colour = 25
        }
    },
    Vehicles = {
        spawnCoords = vector4(-327.9745, -1523.6442, 27.2503, 269.1730),
        distanceParking = 20.0,
        model = "trash2",
        marker = {
            type = 0,
            size = vector3(0.9, 0.9, 0.9),
            color = {
                r = 55,
                g = 182,
                b = 66,
                a = 150   
            },
            distance = 20.0
        },
        trashCount = 2
    }
}

Config.RoutesSettings = {
    Blip = {
        sprite = 952,
        scale = 0.7,
        colour = 2
    },
    Zone = {
        colour = 11
    },
    TrashModels = {
        "hw1_13_props_dump01alod1",
        "hw1_13_props_dump01alod",
        "prop_bin_08open",
        "prop_recyclebin_04_b",
        "prop_fragtest_cnst_01",
        "prop_cs_bin_02",
        "prop_recyclebin_03_a",
        "prop_cs_bin_01_skinned",
        "prop_dumpster_3a",
        "prop_dumpster_4a",
        "v_ind_bin_01",
        "prop_cs_bin_01",
        "prop_cs_bin_03",
        "prop_dumpster_4b",
        "prop_bin_04a",
        "prop_bin_07b",
        "prop_dumpster_02a",
        "prop_dumpster_02b",
        "zprop_bin_01a_old",
        "prop_bin_02a",
        "m23_2_prop_m32_dumpster_01a",
        "prop_bin_07c",
        "prop_bin_01a",
        "prop_bin_07a",
        "prop_bin_05a",
        "prop_container_01a",
        "prop_container_01b",
        "prop_container_02a",
        "prop_container_02b",
        "prop_container_03_ld",
        "prop_container_ld_g1",
        "prop_container_01mb",
        "prop_container_01rb",
        "prop_container_02mb",
        "prop_container_03b",
        "prop_dumpster_01a"
    },
    GarbageMarker = {
        type = 0,
        size = vector3(0.4, 0.4, 0.4),
        color = {                                                       
            r = 55,
            g = 182,
            b = 66,
            a = 150
        },
        distance = 15.0, 
        height = vector3(0.0, 0.0, 2.0)

    },
    GettingTrash = {
        animations = {
            dict = "anim@scripted@player@fix_chop_petting@male@",
            name = "petting"
        },
        prop = {
            "prop_cs_rub_binbag_01"
        }
    },
    CarryTrashAnimation = {
        dict = "anim@heists@narcotics@trash",
        name = "idle"
    },
    DisableActions = {
        jump = true,
        attack = true,
        aim = true,
        run = true
    },
    DropTrashInVehicle = {
        marker = {
            type = 0,
            size = vector3(0.4, 0.4, 0.4),
            color = {
                r = 55,
                g = 182,
                b = 66,
                a = 150   
            },
            distance = 10.0
        }
    },
    DropTrashInVehicleAnimation = {
        dict = "anim@heists@narcotics@trash",
        name = "throw_b"
    }, 
    ShowHelperText = true

}

Config.Routes = {
    {
        Zone = {
            coords = vector3(-104.9505, -1416.2239, 29.7637),
            distance = 150.0
        },
        Rework = {
            item = "money_item",
            caunt = 15
        }
    },
    {
        Zone = {
            coords = vector3(-1432.9454, -393.1445, 36.3121),
            distance = 150.0
        },
        Rework = {
            item = "money_item",
            caunt = 15
        }
    }
}
