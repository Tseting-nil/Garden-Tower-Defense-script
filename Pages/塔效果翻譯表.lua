--[[
================================================================
            花園塔防 GTD｜塔效果翻譯表（資料模組）
================================================================
本檔不需單獨執行，由「塔效果翻譯.lua」與「隊友塔查看.lua」下載載入。

【回傳格式】依玩家語言回傳對應的翻譯表：
  {
      Lang    = "zh" | "en",
      Units   = { [unit_id]  = "塔 / 敵人效果說明" },  -- 對應 Params.CustomDescription
      Traits  = { [trait_id] = "詞條說明" },           -- 對應 RollableTraits 的 Params.Description
  }
  語言讀取 Tsetingnil_script/keysystem.json 的 script_language（預設中文）。
  英文的 Units / Traits 為空表，代表保留遊戲原文。

【維護】
  - 修改翻譯：調整內容後更新 Gist 即可，玩家下次執行時會自動下載新版。
  - 新增語言：在 TRANSLATIONS 加一組，並在下方語言偵測加入對應判斷。
================================================================
--]]

-- 語言偵測（與 API 相同規則）
local Lang = "zh"
pcall(function()
	if isfile and isfile("Tsetingnil_script/keysystem.json") then
		local content = readfile("Tsetingnil_script/keysystem.json")
		if content then
			local scriptLang = nil
			-- 優先以 JSON 解析
			local ok, data = pcall(function()
				return game:GetService("HttpService"):JSONDecode(content)
			end)
			if ok and data and data.script_language then
				scriptLang = data.script_language
			else
				-- 解析失敗時以字串比對取值
				scriptLang = content:match('"script_language"%s*:%s*"([^"]+)"')
			end

			if scriptLang then
				local sl = scriptLang:lower()
				if sl:find("chinese") or sl:find("zh") then
					Lang = "zh"
				elseif sl:find("english") or sl:find("en") then
					Lang = "en"
				end
			end
		end
	end
end)

local TRANSLATIONS = {
	zh = {
		-- ============================================================
		-- 塔 / 敵人說明（key = unit id）
		-- 變種塔（如 bronze / silver / gold 系列）會自動沿用本體翻譯，不必另列
		-- ============================================================
		Units = {
			-- 敵人
			enemy_blood_eye_spider = "持續暈眩射程內最近的一座單位，直到牠被擊倒為止。該單位被放開後，等待 1 秒再暈眩下一座。",
			enemy_boss_gravewing = "每 10 秒可進入無敵狀態，3 秒內單位無法鎖定牠。",
			enemy_boss_skeleton_spider = "存活期間削弱地圖上所有單位，傷害與射程降低 25%。",
			enemy_boss_space_4leg = "免疫火焰與冰凍攻擊。會召喚隨機敵人。",
			enemy_boss_space_spider = "被擊倒時會生成異星帝王蜘蛛敵人。",
			enemy_boss_zombie_fly = "每 40 秒對地圖上所有單位施毒，5 秒內每分鐘攻擊次數（APM）減半。",
			enemy_chameleon = "可以偽裝，暫時躲避單位攻擊。",
			enemy_ice_widow_boss = "暈眩射程內的單位。",
			enemy_king_stag_beetle = "每 20 秒分裂出 1 隻鍬形蟲。",
			enemy_mole = "可以鑽入地下，暫時躲避單位攻擊。",
			enemy_moon_moth = "每秒回復生命值。",
			enemy_pumpkin_bug = "生命值降到 30% 以下時，速度提升 75%（只觸發一次）。",
			enemy_rhino_beetle = "每 20 秒分裂出 1 隻犀牛甲蟲。",
			enemy_sand_worm = "可以鑽入地下，暫時躲避單位攻擊。",
			enemy_scarecrow_grasshopper = "每秒回復最大生命值的 3%，每秒最多回復 50,000。",
			enemy_space_drill = "可以鑽入地下，暫時躲避單位攻擊。",
			enemy_space_mecha_bug = "擁有額外生命值的護盾。部分單位可以穿透或解除這層護盾。",
			enemy_space_molten = "暈眩範圍內的單位。",
			enemy_space_snail = "提升範圍內敵人的速度。",
			enemy_stag_beetle = "每 20 秒分裂出 1 隻鍬形蟲。",
			enemy_stun_fly = "暈眩射程內的單位。",

			-- 道具
			dp_gd_more_storage = "此物品只能由從未購買過額外單位倉庫的玩家使用！",

			-- 塔
			unit_accumulator = "放置多座 Linkberry 時，每多一座 Linkberry 傷害 +20%，最多 +100%。",
			unit_acid_chomp = "交替使用不同攻擊。對敵人附上孢子，2 秒後爆炸，對目前射程一半範圍內的其他敵人造成傷害。",
			unit_alien_plant = "無視敵人護盾。",
			unit_angel_clover = "附著在另一座單位上，永久提升其傷害，升到滿級最高 x2。被附著的單位賣掉時，Holographic Clover 也會一起賣掉。",
			unit_aquasia = "生成最多 4 個迷你 Luminesia，對碰到的敵人造成傷害。敵人碰到後迷你 Luminesia 就會消失。",
			unit_axolotl_cave = "生成最多 3 隻蠑螈對敵人造成傷害。讓動態射程內的單位免疫敵人暈眩。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_banana_peel = "暈眩敵人，使其停止前進。",
			unit_beamstock = "技能：15 秒內射程 +100%、每分鐘攻擊次數（APM）+20%。",
			unit_beesting = "每次攻擊有 10% 機率標記敵人，3 秒內所有單位對其傷害 +20%。",
			unit_bell_wing = "暈眩敵人，使其停止前進。敲響每個鈴鐺時，暫時提升射程內所有單位的射程與每分鐘攻擊次數（APM）。",
			unit_berry_bush = "升級後最多生成 3 個 Enchanterberries。Enchanterberries 會傷害敵人，並催眠敵人往反方向走、攻擊其他敵人。",
			unit_berserker = "交替使用不同攻擊。吹響號角，2.4 秒內每分鐘攻擊次數（APM）最多 +65%。",
			unit_bibo = "對生命值低於 50% 的敵人造成 x2 傷害。",
			unit_big_mushroom = "交替使用不同攻擊。重擊敵人腳下地面，對 10 範圍內的其他敵人造成傷害。",
			unit_birthday_cake = "慶祝 Garden Tower Defense 一週年 Bloomday 的單位。技能：時間停止，使敵人停止前進；同時讓所有單位傷害最高 x2、每分鐘攻擊次數（APM）最高 +10%。",
			unit_black_clover = "射程內其他所有單位傷害最高 +35%。",
			unit_black_hole = "攻擊後對敵人附加「吸取」效果：傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。可用範圍攻擊同時命中最多 5 個敵人。",
			unit_black_rose = "交替使用不同攻擊。電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
			unit_bloodvine = "攻擊後對敵人附加「吸取」效果：傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。",
			unit_blossom_blast = "有彈藥，彈藥量隨升級增加。",
			unit_blossom_shooter = "技能：15 秒內射程無限。",
			unit_bouncy_shroom = "發射會彈跳的迷你彈跳菇，每次彈跳都造成傷害。",
			unit_bronze_lucky_lunger = "交替使用不同攻擊：睡眠與巧克力。有 15% 機率標記敵人，3 秒內所有單位對其傷害 +11%。",
			unit_bubble_flower = "對敵人發射泡泡，讓敵人往後漂。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_bubble_stem = "把敵人往後吹，距離依敵人生命值而定。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_bunny_flower = "攻擊會在最多 5 個額外敵人之間連鎖跳躍，每跳一次傷害降低。",
			unit_bunny_golem = "技能：釋放能量衝擊，對射程內所有敵人造成 x50 傷害。",
			unit_butterfly_hive = "射程無限。生成蝴蝶，提升其他單位的射程。",
			unit_candy_cane = "技能：放置糖果拐杖牆，對敵人造成傷害。",
			unit_card_shroom = "技能：每 60 秒抽一張隨機卡牌，讓射程內所有單位獲得 45 秒的隨機加成（速度、金錢、傷害或射程）。",
			unit_castle = "生成會噴火球的龍攻擊敵人。攻擊會在最多 4 個額外敵人之間連鎖跳躍，每跳一次傷害降低。技能：暫時召喚一群龍。",
			unit_champions_beesting = "每次攻擊有 10% 機率標記敵人，3 秒內所有單位對其傷害 +25%。",
			unit_chicken_coop = "生成雞。每隻雞造成的總傷害等於牠的生命值。",
			unit_choco_flower = "留下巧克力水窪，把敵人永久變成巧克力，所有單位對其傷害 +10%。",
			unit_choco_tesla = "電擊連鎖攻擊敵人，命中射程內所有敵人。同時把敵人永久變成巧克力，所有單位對其傷害 +10%。",
			unit_christmas_bell = "暈眩敵人，使其停止前進。敲響鈴鐺時，暫時提升射程內所有單位的傷害。",
			unit_clock_flower = "技能：時光倒流，把敵人往回送 2 秒。",
			unit_coffin_plant = "捕捉走過它的敵人，把敵人困在原地並持續造成傷害，之後再放開。被捕捉的敵人仍可被其他單位攻擊、無法被推動或移動，並產生更多金錢。",
			unit_coil = "電擊連鎖攻擊敵人，命中射程內所有敵人。",
			unit_confusion_plant = "讓敵人往反方向走。",
			unit_contagious = "讓敵人感染「傳染」，造成永久傳染傷害，並擴散到範圍 5 內的其他所有敵人。被感染的敵人被擊倒後，會在原地留下一段時間的傳染區域。",
			unit_coral = "敵人離此單位越遠，範圍攻擊半徑越大。交替使用不同攻擊。每第 4 次攻擊同時對敵人發射 3 顆泡泡。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_corn_booster = "提升所有玉米系單位（Corn、Juggercorn、Wrecking Cornball）的傷害、每分鐘攻擊次數（APM）與射程。",
			unit_cosmic_flower = "每次攻擊有 2% 機率削弱敵人，使其受到的傷害 +15%。",
			unit_crimson_stem = "同時發射最多 5 道光束，最多鎖定 5 個敵人。升到滿級後解鎖技能：10 秒內同時發射最多 20 道光束、射程無限。每次攻擊有 10% 機率標記敵人，3 秒內所有單位對其傷害 +15%。",
			unit_crystal_flower = "技能：10 秒內 Gemspire 傷害 +75%。同時發射 3 道光束，最多鎖定 3 個敵人。",
			unit_cursed_fruit = "有隨機機率複製出最多 x5 個相同單位，DPS 變成 x5。",
			unit_cyborg_farmer = "交替攻擊：發射一道光束，並向兩側折射到 6 範圍內的其他敵人。",
			unit_daisy = "每次攻擊有 10% 機率削弱敵人，使其受到的傷害 +10%。",
			unit_dark_fruit = "削弱敵人，使其受到的傷害 +10%。",
			unit_dark_spikes = "交替使用不同攻擊。向 8 個方向發射 8 枚碎片，射程 20。每次攻擊有 10% 機率標記敵人，3 秒內所有單位對其傷害 +15%。",
			unit_deathesia = "每次攻擊有 20% 機率讓傷害 +7.5%，持續 5 秒。",
			unit_divine_orb = "投擲光球，對碰到的敵人造成範圍傷害。技能：額外投擲 30 顆光球。攻擊後對敵人附加「吸取」效果：傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。",
			unit_divine_sunflower = "攻擊會在最多 5 個額外敵人之間連鎖跳躍，每跳一次傷害降低。每次攻擊有 5% 機率削弱敵人，使其受到的傷害 +10%。",
			unit_dream_petal = "不攻擊時累積並儲存能量，能量越多傷害越高。攻擊時能量會減少。",
			unit_dynosprout = "發射炸藥，爆炸造成範圍傷害，並向 8 個方向再分裂出 8 枚炸藥，各自爆炸造成範圍傷害。",
			unit_easter_flower = "敵人離此單位越近，傷害越高。",
			unit_easter_petal = "同時發射 8 道光束，最多鎖定 8 個敵人。技能：時間停止，使敵人停止前進。",
			unit_egg_basket = "交替使用不同攻擊：火焰、冰凍、毒。升到第 4、5 級時三種攻擊同時發射。",
			unit_egg_beam = "技能：發射復活節彩蛋，在落點造成射程 20 的範圍傷害。",
			unit_egg_claw = "抓住並暈眩敵人，使其停止前進。",
			unit_egg_whip = "讓敵人感染「傳染」，造成永久傳染傷害，並擴散到範圍 5 內的其他所有敵人。被感染的敵人被擊倒後，會在原地留下一段時間的傳染區域。",
			unit_eggplantinum = "跟著你移動，射程跟著你走。技能：時間停止，使敵人停止前進。",
			unit_electric_beetroot = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
			unit_electric_jabber = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
			unit_electric_orange = "交替使用不同攻擊。電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
			unit_electric_root = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。技能：對射程內所有敵人造成範圍電擊傷害，每個敵人最多 20,000。",
			unit_electric_sprout = "電擊連鎖攻擊敵人，命中射程內所有敵人。技能：對射程內所有敵人額外攻擊 3 次。Electrosprout 射程內每放一座特斯拉類單位，該單位傷害 -15%，最多 -75%（不影響 Electrosprout 自己）。",
			unit_envelope = "這是獨特的劇情道具。信裡寫著：「我是黑暗中的低語，是你所見一切的終點。我奪走你的呼吸卻從不留下，還讓囚犯重獲自由。我是什麼？」",
			unit_evil_shroom = "3 秒後爆炸，造成「核爆」範圍傷害。",
			unit_evil_stem = "連續攻擊同一個敵人會逐漸提高減速，最多減速 40%。對同一個敵人每第 5 次攻擊，造成 12 範圍內的範圍傷害。",
			unit_evolution_flower = "隨時間再生，傷害逐漸提升。再生上限為傷害 x1.5。",
			unit_excalibur = "射程內其他所有單位傷害最高 +20%。每次攻擊都會標記敵人，2 秒內所有單位對其傷害最高 +20%。",
			unit_eye_flower = "傷害每秒 +20%，最高 x2。停止攻擊時連擊重置。每 5 秒對被命中敵人周圍 12 範圍內的其他敵人造成範圍傷害。",
			unit_eyeball = "交替使用不同攻擊。每隔一次攻擊，對射程內所有敵人造成傷害。",
			unit_fan_plant = "把敵人往後吹，距離依敵人生命值而定。",
			unit_fat_sprinkler = "提升射程內所有單位的每分鐘攻擊次數（APM）。有 200 發彈藥。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。技能：10 秒內提升 Sprinklord 的每分鐘攻擊次數（APM）與傷害。",
			unit_festive_berries = "攻擊後對敵人附加「吸取」效果：傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。",
			unit_fire_bloom = "同時發射最多 5 道光束，每道鎖定不同敵人。",
			unit_fire_loop = "每分鐘攻擊次數（APM）每秒 +10%，最高 x1.5。停止攻擊時連擊重置。",
			unit_firework_billy = "技能：發射高傷害、大範圍的火箭，使用後 Gnomebang 單位會被摧毀。煙火火箭會對敵人造成火焰傷害。",
			unit_firework_plant = "每次攻擊有 2% 機率對敵人造成 x12 次「命中」，範圍攻擊半徑暫時從 6 提升到 20。",
			unit_fisherman = "把敵人往後甩，距離依敵人生命值而定。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_flame_leaf = "暈眩敵人，使其停止前進。",
			unit_fountain = "有 40% 機率把敵人往後帶。",
			unit_fountain_bird = "有 40% 機率把敵人往後帶。",
			unit_frank = "暈眩敵人，使其停止前進。",
			unit_frozen_spike = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
			unit_gargoyle = "每 10 秒召喚一隻「飛行蝙蝠」，存在 8 秒。",
			unit_ghost_lily = "被命中的敵人變成幽靈 4 秒。幽靈無法被單位鎖定、也無法攻擊，但受到範圍與效果攻擊的傷害 x2。Boss 有 50% 機率抵抗。同一個敵人每 4.5 秒最多被變成幽靈一次。",
			unit_ghost_shroom = "跟著你移動，射程跟著你走。冰凍敵人。",
			unit_gift_plant = "攻擊後對敵人附加「吸取」效果：傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。",
			unit_gingerbread_windmill = "放置滿 180 秒後啟動，最終種子收入額外 +5%；但地圖上每座單位傷害 -2.5%。可與其他玩家放置的 Gingerbread Seedmill、Seedmill 疊加。",
			unit_glue_bomb = "爆炸後留下膠水讓敵人減速，同時造成傷害。",
			unit_gold_clover = "提升射程內其他所有單位每次攻擊打出 x2.1 暴擊的機率。升級與技能費用最多折扣 15%。技能：獲得的金錢最多 x2。",
			unit_gold_lucky_lunger = "交替使用不同攻擊：睡眠與巧克力。有 15% 機率標記敵人，3 秒內所有單位對其傷害 +12%。",
			unit_golem = "投擲石塊，暈眩被命中的敵人，使其停止前進。",
			unit_grandma = "對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_grave_crawler = "敵人生命值低於 25% 且目前生命值不超過 100,000 時，有 10% 機率直接消滅。",
			unit_green_lights = "電擊連鎖攻擊敵人，命中射程內後方所有敵人，造成 x2 傷害。",
			unit_grim_gardener = "跟著你移動，射程跟著你走。每次揮砍對目標周圍所有敵人造成完整傷害。持續攻擊時每分鐘攻擊次數（APM）逐漸提升，30 秒後達到 x1.5。技能：消滅 15 範圍內生命值不超過 20% 的所有敵人。",
			unit_hot_air_balloon = "暈眩敵人，使其停止前進。",
			unit_hot_leaf = "暈眩敵人，使其停止前進。",
			unit_hw_pepper = "技能：引發多次爆炸。",
			unit_hypno = "同時發射最多 2 道光束，最多鎖定 2 個敵人。每道光束都會催眠敵人並造成生命流失，讓敵人往反方向走、攻擊其他敵人。傷害依升級等級累積為敵人最大生命值的 2%～14%，最多 14M。",
			unit_ice_dragon = "巡邏並造成範圍傷害與冰凍。",
			unit_ice_eyeball = "技能：冰凍射程內所有敵人 75%，持續 4 秒。",
			unit_ice_gem = "同時發射最多 5 道光束，每道鎖定不同敵人。冰凍敵人。",
			unit_ice_rafflesia = "黏附在敵人身上，造成範圍傷害與冰凍。",
			unit_ice_sunflower = "召喚冰霜射線，脈衝 2 秒造成傷害。",
			unit_icecream = "有 25% 機率把敵人永久變成巧克力，所有單位對其傷害 +10%。",
			unit_ink_sprout = "暈眩敵人，使其停止前進。",
			unit_iris = "投擲最多 9 顆水晶，把碰到的敵人傳送回後方。技能：時間停止，使敵人停止前進。",
			unit_ivy_shooter = "有彈藥，彈藥量隨升級增加。換彈前最後一發造成 x5 暴擊傷害。",
			unit_jelly_shroom = "暈眩敵人，使其停止前進；電擊連鎖以範圍攻擊命中射程內後方的多個敵人。",
			unit_kelp = "把敵人往後擊退，距離依敵人生命值而定。",
			unit_lanternwood = "投擲燈籠，命中時爆炸造成範圍傷害並點燃敵人。每次攻擊還會在路上留下持續 12 秒的燃燒水窪，點燃走過的敵人。最多同時 3 個水窪。",
			unit_laser_flower = "技能：發動太陽閃焰「核爆」，造成瞬間毀滅。",
			unit_lava_banana_peel = "暈眩敵人，使其停止前進。",
			unit_lava_booster = "射程內其他帶火焰的單位，火焰傷害最高 +30%。",
			unit_lava_flower = "技能「地板是岩漿」：生成上升的岩漿，對碰到的敵人造成傷害。",
			unit_lava_golem = "交替使用不同攻擊。鑽擊地面，對射程內所有敵人造成傷害。技能：讓鑽擊帶火焰，提升傷害與持續時間。",
			unit_lava_shroom = "技能：讓 12 範圍內的敵人往反方向走。",
			unit_lava_trunk = "螢火蟲動態射程內其他帶火焰的單位，火焰傷害 +25%。",
			unit_life_crystal = "提升射程內其他單位的射程。隨時間再生，傷害逐漸提升，再生上限為傷害 x1.8。技能：射程內每個敵人有 15% 機率被變成較弱的敵人。同時發射最多 6 道光束，每道鎖定不同敵人。",
			unit_life_flower = "有 3 個傷害階段。持續攻擊同一個目標時階段逐漸提升，傷害最多 +60%。換目標時傷害階段重置。",
			unit_life_tree = "每隔一段時間解除單位身上的敵人暈眩。",
			unit_lucky_chomp = "交替使用不同攻擊：火焰、毒、傳染。",
			unit_lucky_grabber = "抓住並暈眩敵人，使其停止前進。分別有 5%、2.5%、0.5% 機率同時暈眩 2 個、3 個、射程內所有敵人。",
			unit_lucky_lunger = "交替使用不同攻擊：睡眠與巧克力。有 15% 機率標記敵人，3 秒內所有單位對其傷害 +10%。",
			unit_lucky_plant = "提升射程內其他所有單位每次攻擊打出 x2.5 暴擊的機率。另外讓射程內其他所有單位傷害最高 +10%。",
			unit_lucky_portal = "技能：召喚傳送門，把敵人傳送回後方。進入傳送門的敵人生命值低於 25% 且目前生命值不超過 25,000 時，有 5% 機率直接消滅。",
			unit_lucky_sword = "這是獨特的幸運方塊活動道具。",
			unit_lucky_thrower = "投擲幸運方塊，對碰到的敵人造成範圍傷害。幸運方塊有機率對敵人施加冰凍、傳染、毒或火焰。",
			unit_lullaby = "讓敵人睡眠。睡眠時所有單位對其傷害 +60%，之後降為 +25% 直到效果結束。",
			unit_magic_pot = "召喚龍捲風，旋轉 5 秒造成傷害。",
			unit_magma_dragon = "技能：10 秒內速度從 18 提升到 30。",
			unit_magnet = "技能：釋放電磁脈衝，對射程內所有敵人造成範圍電擊傷害，每個敵人最多 6,500。把敵人往後推，距離依敵人生命值而定。每多放一座 Magnetroot，磁力越強。",
			unit_mango = "技能：6 秒內每分鐘攻擊次數（APM）x3、範圍攻擊半徑 +6。",
			unit_mech_saw = "技能：8 秒內每分鐘攻擊次數（APM）+100%；使用技能後此單位有 4 秒無法攻擊。",
			unit_mechanical_flower = "傷害每秒 +20%，最高 x2。停止攻擊時連擊重置。",
			unit_medusa = "發射雷射，傷害路徑上所有敵人。同時把敵人暫時石化，使其停止前進，所有單位對其傷害 +25%。",
			unit_mermaid = "投擲三叉戟，傷害路徑上所有敵人。",
			unit_metal_flower = "交替使用不同攻擊。電擊連鎖攻擊敵人，命中射程內所有敵人。每隔一次攻擊，對射程內所有敵人造成傷害。",
			unit_meteor_plant = "在火山島地圖上保護單位不被隕石暈眩。",
			unit_minigun_plant = "技能：依敵人生命值造成額外傷害，最多額外 95,000。",
			unit_minions = "跟著你移動，射程跟著你走。升級後最多生成 3 個 Budyguard。第 1 級的 Budyguard 暈眩敵人使其停止前進；第 3 級的讓敵人減速 15%；第 5 級的有 10% 機率標記敵人，3 秒內所有單位對其傷害 +10%。",
			unit_mint_bloom = "對敵人發射光球，把敵人往後推。",
			unit_missing_poster = "這是獨特的劇情道具。",
			unit_mortar = "技能：改變 Mortarfern 的目標位置。發射砲彈爆炸造成範圍傷害，並留下酸液水窪，對碰到的敵人持續造成酸液傷害。射程無限。不會自動鎖定敵人。",
			unit_multi_flower = "交替使用不同攻擊：火焰、冰凍、毒。升到第 4、5 級時三種攻擊同時發射。",
			unit_ogre = "交替使用不同攻擊。用減速攻擊命中射程內所有敵人。",
			unit_orb_lobber = "暈眩敵人，使其停止前進。放置多座 Beaconbud 時，每多一座 Beaconbud 射程 +10%，最多 +80%。",
			unit_orb_stems = "技能：最多 7 次攻擊傷害 x4，攻擊會隨時間充能。",
			unit_parasite_plant = "讓敵人感染「傳染」，每次攻擊疊加一層，最多 300 層，造成永久傳染傷害，並擴散到範圍 5 內的其他所有敵人。被感染的敵人被擊倒後，會在原地留下一段時間的傳染區域。",
			unit_patricia_hat = "這是獨特的劇情道具。",
			unit_pea_lobber = "攻擊會在最多 2 個額外敵人之間連鎖跳躍，每跳一次傷害降低。",
			unit_peppermint = "能量充滿時對敵人造成高傷害攻擊。能量沒充滿就不會攻擊。",
			unit_pesticider = "每次攻擊有 35% 機率造成毒傷害。被命中的敵人被擊倒時會爆炸，傷害其他敵人。",
			unit_petriflora = "攻擊前方錐形範圍內所有敵人。同時把敵人暫時石化，使其停止前進，所有單位對其傷害 +25%。",
			unit_pink_rose = "催眠敵人，讓敵人往反方向走、攻擊其他敵人。",
			unit_plasma_blaster = "不攻擊時累積並儲存能量，能量越多傷害越高。攻擊時能量會減少。技能：立刻充滿能量，並維持滿能量 5 秒。",
			unit_poison_bite = "攻擊時能量增加，能量越多傷害越高，最多 x2。傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。",
			unit_poison_plant = "攻擊會對敵人施加「虛無」。虛無傷害隨時間逐漸提升，最多 13,500。",
			unit_poison_vine = "對敵人造成毒傷害。敵人速度越低，受到的毒傷害越高。",
			unit_potion_plant = "投擲藥水瓶爆炸造成範圍傷害，並暫時擴大藥水爆炸範圍內所有原本就有範圍攻擊的單位的範圍。",
			unit_power_flower = "每次攻擊有 7.5% 機率爆頭主要目標，造成 x2 暴擊傷害。範圍攻擊波及的目標不會被爆頭。",
			unit_pump = "射程無限，「澆水」給其他單位，提升其每分鐘攻擊次數（APM）。",
			unit_punch_potato = "每次攻擊有 1% 機率對生命值低於 25% 的敵人造成 x100 傷害。",
			unit_purple = "對生命值低於 25% 的敵人傷害 +25%。",
			unit_quantum_stem = "同時發射最多 4 道光束，最多鎖定 4 個敵人。",
			unit_queen_rose = "技能：15 秒內射程內所有單位傷害 +25%、每分鐘攻擊次數（APM）+20%、射程 +30%。",
			unit_range_booster = "提升射程內其他單位的射程。",
			unit_robo_pellet = "發射一道光束，並折射到後方 12 範圍內的其他敵人。對中毒的敵人傷害 +20%。",
			unit_rosebeam = "暈眩敵人，使其停止前進。",
			unit_rosebud = "攻擊會在最多 7 個額外敵人之間連鎖跳躍，每跳一次傷害降低；攻擊還會複製一份反向連鎖。",
			unit_rotten_tomato = "這是過去神秘尋寶活動的獨特單位。裝備 Rotten Tomato 可以朝其他人丟爛番茄。",
			unit_scary_tree = "留下酸液水窪，對碰到的敵人持續造成酸液傷害。",
			unit_scientist = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
			unit_sea_chest = "捕捉敵人並持續造成傷害，之後再放開。被捕捉的敵人會產生更多金錢。",
			unit_sea_chomp = "每次終結攻擊有 3% 機率對生命值低於 30% 的敵人造成 x150 傷害，終結攻擊每 10 次攻擊觸發一次。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。攻擊後對敵人附加「吸取」效果。",
			unit_sea_dragon = "在一片範圍內巡邏，對範圍內的敵人造成傷害。電擊連鎖攻擊敵人，命中射程內後方所有敵人。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_seed_wing = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
			unit_seedling_rune = "這是獨特的劇情道具。",
			unit_serpent = "技能：放置迷宮牆，對敵人造成傷害。",
			unit_shockfrost = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。冰凍敵人。",
			unit_silly_mushroom = "暈眩敵人，使其停止前進。",
			unit_silver_lucky_lunger = "交替使用不同攻擊：睡眠與巧克力。有 15% 機率標記敵人，3 秒內所有單位對其傷害 +11.5%。",
			unit_skeleflower = "開始攻擊後的前 5 秒，每分鐘攻擊次數（APM）提升。",
			unit_sniper = "發射子彈，傷害路徑上所有敵人；每發子彈命中的前 5 個敵人之後，傷害逐漸降低。攻擊後對敵人附加「吸取」效果：傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。有 5 發彈藥。每發子彈命中的前 5 個敵人，護盾會被解除 3 秒；護盾被解除後，同一個敵人 5 秒內不會再被解除護盾。",
			unit_snow_shovel = "雪地摩托把敵人往後甩，距離依敵人生命值而定。",
			unit_snowman = "讓射程內的單位有 20% 機率冰凍敵人，機率隨升級提升。也會強化原本就有冰凍的單位。",
			unit_soulshard = "瞬移到地圖上任何敵人旁邊，炸成一團雲霧，對雲霧內所有敵人造成傷害。被命中的敵人會混亂並被吸取。射程加成會讓雲霧變大。",
			unit_space_booster = "提升射程內單位的每分鐘攻擊次數（APM），並縮短射程內單位的技能冷卻。",
			unit_space_purple = "發射一道光束，並折射到後方 8 範圍內的其他敵人。",
			unit_spade = "這是獨特的劇情道具。",
			unit_spellbook = "攻擊會對敵人施加「虛無」。虛無傷害隨時間逐漸提升，最多 2,750。技能：對射程內所有敵人施加虛無。",
			unit_spirit_flower = "暈眩敵人，使其停止前進。",
			unit_sprinkler = "提升射程內所有單位的每分鐘攻擊次數（APM）。",
			unit_squid_stem = "發射會黏在敵人身上的烏賊，讓敵人減速，並每 4 秒造成一次傷害。",
			unit_star_shroom = "投擲星形手裏劍，在最多 3 個額外敵人之間連鎖跳躍，每跳一次傷害降低。讓被命中的敵人睡眠：所有單位對其傷害 +60%，之後降為 +30% 直到效果結束。",
			unit_starbud = "技能：10 秒內射程內單位的每分鐘攻擊次數（APM）+12.5%。",
			unit_starfruit = "攻擊會在最多 3 個額外敵人之間連鎖跳躍，每跳一次傷害降低。",
			unit_stem_beam = "放置多座 Clusterplant 時射程可以疊加。技能：在範圍光球與單體雷射之間切換。",
			unit_stem_blast = "攻擊會在最多 9 個額外敵人之間連鎖跳躍，每跳一次傷害降低。",
			unit_stray_cat = "敵人離此單位越遠，範圍攻擊半徑越大。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_stringshade = "飄向敵人並附身其中一個，催眠它往反方向走、攻擊其他敵人。離開宿主時對其施加「吸取」。放置上限由整隊共用。",
			unit_stun_flower = "暈眩敵人，使其停止前進。",
			unit_stun_leaf = "暈眩敵人，使其停止前進。每分鐘攻擊次數（APM）會依目標切換設定而不同。",
			unit_stun_root = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人，並暈眩被命中的敵人使其停止前進。",
			unit_surge_root = "召喚電流脈衝，移動 2 秒造成傷害，同時以電擊連鎖攻擊後方的多個敵人。",
			unit_timekeeper = "一般模式下，基地生命值歸 0 時使用；生存模式下，所有人都被擊倒時使用。提升射程內單位的每分鐘攻擊次數（APM）。技能：時間停止，使敵人停止前進。",
			unit_toxic_altar = "同時發射最多 6 道光束，最多鎖定 6 個敵人。交替使用不同攻擊。投擲毒球造成射程 20 的範圍傷害，並留下酸液水窪，對碰到的敵人持續造成酸液傷害。",
			unit_toxic_mushroom = "留下最多 4 個酸液水窪，對碰到的敵人持續造成酸液傷害。",
			unit_traffic_light = "在綠燈、黃燈、紅燈之間輪替。綠燈為預設，沒有效果；黃燈讓敵人減速；紅燈暈眩敵人，使其停止前進。",
			unit_tree_golem = "技能：引發地震，讓敵人減速並造成 x5 傷害。重擊敵人腳下地面，讓衝擊點 10 範圍內的其他敵人減速，越靠近衝擊點減速越強。",
			unit_tri_lucky = "技能：每 45 秒開一個幸運方塊，讓射程內所有單位獲得 35 秒的隨機加成（速度、金錢、傷害、射程、減速或冷卻縮短）。",
			unit_tri_orb = "無視敵人護盾。",
			unit_triangles = "需要放置 3 座 Triangrove 圍成一個區域。進入區域的敵人無法使用自己的攻擊方式，所有單位對區域內敵人的傷害 +15%。遠古克拉肯 Boss 與克拉肯 Boss 免疫 Triangrove。",
			unit_trident = "技能：召喚海嘯，造成傷害並把敵人往後擊退，距離依敵人生命值而定。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。傷害隨時間疊加，並讓敵人減速 20% 直到效果結束。",
			unit_trithorn = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。每次攻擊有 15% 機率造成 x3 暴擊傷害（暴擊不包含毒傷害）。",
			unit_umbra = "讓躲藏的敵人無法躲藏。",
			unit_val_blossom = "有 1% 機率催眠敵人，讓它轉身攻擊其他敵人。",
			unit_val_heart = "儲存單位造成的傷害，最多 2,000,000。每秒儲存上限依伺服器人數而定：1 人 16,000、2 人 18,000、3 人 20,000、4 人 22,000。技能：釋放儲存的傷害，平均分給射程內所有敵人。此單位無法被傷害增益單位（例如 Clover）強化。",
			unit_venus_double = "留下酸液水窪，對碰到的敵人持續造成酸液傷害。",
			unit_vine_eye = "技能：放置藤蔓，藤蔓會以範圍效果暈眩敵人（停止前進）並造成傷害。",
			unit_vine_hair = "把敵人往後甩，距離依敵人生命值而定。",
			unit_vitality = "發射光球吸取敵人生命，帶回基地，每次攻擊回復基地生命值。基地滿血時改為提升基地最大生命值，最多 1,000,000。生存模式下改為治療生命最低的玩家，最多 200。",
			unit_void_bloom = "發射產生重力的光球，讓目標敵人停止前進，並把附近敵人拉過來。重力持續造成傷害，最後內爆造成額外傷害。",
			unit_void_lucky = "發射雷射，傷害路徑上所有敵人。讓敵人往反方向走。",
			unit_void_petal = "發射雷射，傷害路徑上所有敵人。技能：切換成「敵人離此單位越遠傷害越高」模式。",
			unit_void_seed = "以範圍攻擊讓敵人往反方向走。每次攻擊都會標記敵人，3 秒內所有單位對其傷害 +15%。",
			unit_volcanic_eyeball = "發射雷射，傷害路徑上所有敵人。技能：15 秒內 Overlord Stem 傷害 +25%。",
			unit_wand_flower = "每次攻擊有 5% 機率把敵人變成較弱的敵人。技能：20 範圍內每個敵人有 5% 機率被變成較弱的敵人。",
			unit_water_cannon = "發射水柱，傷害路徑上所有敵人。交替使用不同攻擊。每隔一次攻擊，對射程內所有敵人造成傷害。對敵人施加「潮濕」：延長電擊連鎖的射程，但會抵抗火焰。",
			unit_well = "生成帶有不同攻擊效果的妖精：減速、混亂、擊退。技能「許願」：暫時提升傷害或每分鐘攻擊次數（APM）。",
			unit_wind_plant = "把敵人往後吹，距離依敵人生命值而定。",
			unit_windmill = "放置滿 180 秒後啟動，最終種子收入額外 +5%；但地圖上每座單位傷害 -2.5%。可與其他玩家放置的 Seedmill、Gingerbread Seedmill 疊加。",
			unit_witch = "交替使用不同攻擊。電擊連鎖攻擊敵人，命中射程內後方的多個敵人，並讓被命中的敵人減速 1 秒。每隔一次攻擊還有 7.5% 機率把敵人變成較弱的敵人。",
			unit_wizard = "施放帶有不同攻擊效果的法術：傷害、冰凍、暈眩、火焰、混亂。",
			unit_wizard_eye = "同時發射 3 道光束，最多鎖定 3 個敵人。被擊倒的敵人有機率被儲存。技能：催眠敵人，並釋放所有儲存的敵人往反方向走、攻擊其他敵人，總傷害等於它們的生命值。",
			unit_worker = "隨時間提升基地生命值，最多 1,000,000。",
			unit_wystical_mushroom = "向 8 個方向發射 8 顆炸彈，爆炸造成巨大範圍傷害。",
			unit_zapper = "電擊連鎖攻擊敵人，命中射程內後方的多個敵人。",
		},

		-- ============================================================
		-- 詞條說明（key = trait id），只翻譯說明，詞條名稱維持原文
		-- ============================================================
		Traits = {
			tr_sight_1 = "射程 +2.5%。",
			tr_sight_2 = "射程 +4.5%。",
			tr_sight_3 = "射程 +6.5%。",
			tr_thrifty_1 = "升級費用 -5%。",
			tr_thrifty_2 = "升級費用 -10%。",
			tr_thrifty_3 = "升級費用 -15%。",
			tr_power_1 = "傷害 +2.5%。",
			tr_power_2 = "傷害 +4.5%。",
			tr_power_3 = "傷害 +6.5%。",
			tr_speed_1 = "APM +2.5%。",
			tr_speed_2 = "APM +4.5%。",
			tr_speed_3 = "APM +6.5%。",
			tr_withering_1 = "施加給敵人的負面狀態持續時間 +10%。",
			tr_withering_2 = "施加給敵人的負面狀態持續時間 +15%。",
			tr_withering_3 = "施加給敵人的負面狀態持續時間 +20%。",
			tr_high_roller = "升級費用 -20%，攻擊產生的金錢 +15%。",
			tr_fertilised = "傷害、APM、射程各 +5%。",
			tr_blastzone = "傷害 +5%，範圍攻擊半徑 +2，範圍傷害衰減最低到 20%。",
			tr_deadeye = "每次攻擊有 12.5% 機率造成雙倍傷害。",
			tr_evergreen = "射程 +15%，升級費用 -20%，單位產生的金錢 +20%，技能冷卻 -15%，並免疫暈眩。",
			tr_propagation = "傷害 +7.5%，範圍攻擊半徑 +4，施加給敵人的負面狀態持續時間 +20%，範圍傷害衰減最低到 30%。",
			tr_overbloom = "傷害 +7.5%，APM +5%，每次攻擊有 5% 機率造成雙倍傷害。",
		},
	},
	-- 英文：遊戲原文即英文，不替換
	en = {
		Units = {},
		Traits = {},
	},
}

-- 不支援的語言退回中文
local selected = TRANSLATIONS[Lang] or TRANSLATIONS.zh
return {
	Lang = Lang,
	Units = selected.Units,
	Traits = selected.Traits,
}
