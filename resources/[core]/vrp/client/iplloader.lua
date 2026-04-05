if cfg.iplload then
	Citizen.CreateThread(function()
		LoadMpDlcMaps()
		EnableMpDlcMaps(true)

		local ipls_to_request = {
			"chop_props", "FIBlobby", "FBI_colPLUG", "FBI_repair",
			"v_tunnel_hole", "TrevorsMP", "TrevorsTrailer", "TrevorsTrailerTidy",
			"farm", "farmint", "farm_lod", "farm_props", "facelobby",
			"CS1_02_cf_onmission1", "CS1_02_cf_onmission2", "CS1_02_cf_onmission3", "CS1_02_cf_onmission4",
			"gr_case10_bunkerclosed", "gr_case9_bunkerclosed", "gr_case3_bunkerclosed",
			"gr_case0_bunkerclosed", "gr_case1_bunkerclosed", "gr_case2_bunkerclosed",
			"gr_case5_bunkerclosed", "gr_case7_bunkerclosed", "gr_case11_bunkerclosed",
			"gr_case6_bunkerclosed", "gr_case4_bunkerclosed",
			"hei_yacht_heist", "hei_yacht_heist_Bar", "hei_yacht_heist_Bedrm",
			"hei_yacht_heist_Bridge", "hei_yacht_heist_DistantLights", "hei_yacht_heist_enginrm",
			"hei_yacht_heist_LODLights", "hei_yacht_heist_Lounge",
			"v_rockclub", "bkr_bi_hw1_13_int", "ufo",
			"shr_int", "shutter_closed", "smboat", "cargoship", "railing_start",
			"sp1_10_real_interior", "sp1_10_real_interior_lod",
			"id2_14_during1", "coronertrash", "Coroner_Int_on",
			"refit_unload", "post_hiest_unload", "Carwash_with_spinners",
			"ferris_finale_Anim", "ch1_02_open",
			"AP1_04_TriAf01", "CS2_06_TriAf02", "CS4_04_TriAf03",
			"scafendimap", "DT1_05_HC_REQ", "DT1_05_REQUEST",
			"FINBANK",
			"ex_sm_13_office_01a", "ex_sm_13_office_01b", "ex_sm_13_office_02a",
			"ex_sm_13_office_02b",
		}

		local ipls_to_remove = {
			"FIBlobbyfake", "farm_burnt", "farm_burnt_lod", "farm_burnt_props",
			"farmint_cap", "farmint_cap_lod", "CS1_02_cf_offmission",
			"hei_bi_hw1_13_door", "shutter_open", "shr_int", "csr_inMission",
			"sp1_10_fake_interior", "sp1_10_fake_interior_lod",
			"id2_14_during_door", "id2_14_during1", "id2_14_during2",
			"id2_14_on_fire", "id2_14_post_no_int", "id2_14_pre_no_int",
			"id2_14_during_door", "Coroner_Int_off", "bh1_16_refurb",
			"jewel2fake", "bh1_16_doors_shut", "ch1_02_closed",
			"scafstartimap", "DT1_05_HC_REMOVE", "DT1_03_Shutter", "DT1_03_Gr_Closed",
		}

		for _, ipl in ipairs(ipls_to_request) do
			RequestIpl(ipl)
		end
		for _, ipl in ipairs(ipls_to_remove) do
			RemoveIpl(ipl)
		end
	end)
end
