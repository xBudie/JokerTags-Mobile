-- JokerTags Mobile: independent labels, no JokerDisplay UIBox.
JokerTagsMobile = {version = '1.0.0'}
print('[JokerTagsMobile] Lovely module loaded v1.0')

local function fmt(n)
    if type(n) ~= 'number' then return tostring(n or '') end
    if number_format and math.abs(n) >= 10000 then return number_format(n) end
    return string.format('%g', n)
end

local RED = {0.88,0.28,0.31,1}
local BLUE = {0.23,0.58,0.92,1}
local GOLD = {0.84,0.65,0.25,1}
local GREEN = {0.37,0.70,0.43,1}
local GREY = {0.50,0.58,0.62,1}

-- Explicit mappings adapted from JokerDisplay's vanilla definitions.
-- Values that depend on a hand being played are not guessed.
local DIRECT_MULT = {
    j_joker=true, j_ceremonial=true, j_ride_the_bus=true,
    j_red_card=true, j_green_joker=true, j_flash=true,
    j_popcorn=true, j_trousers=true, j_swashbuckler=true,
}
local DIRECT_XMULT = {
    j_campfire=true, j_stencil=true, j_madness=true,
    j_vampire=true, j_hologram=true, j_lucky_cat=true,
    j_ramen=true, j_constellation=true, j_steel_joker=true,
    j_obelisk=true, j_throwback=true, j_glass=true, j_hit_the_road=true, j_yorick=true, j_caino=true, j_cavendish=true,
}
local DIRECT_CHIPS = {
    j_runner=true, j_ice_cream=true, j_square=true, j_castle=true, j_wee=true, j_stuntman=true,
}


-- Immutable lookups are defined once, rather than rebuilt every frame.
local POKER_HAND_CONDITIONS = {
    j_jolly='Pair', j_sly='Pair', j_zany='Three of a Kind',
    j_wily='Three of a Kind', j_mad='Two Pair', j_clever='Two Pair',
    j_crazy='Straight', j_devious='Straight',
    j_droll='Flush', j_crafty='Flush',
}
local SUIT_MULT = {
    j_greedy_joker='Diamonds', j_lusty_joker='Hearts',
    j_wrathful_joker='Spades', j_gluttenous_joker='Clubs',
}
local HAND_ONLY = {
    j_smiley=true, j_scary_face=true, j_greedy_joker=true, j_lusty_joker=true,
    j_wrathful_joker=true, j_gluttenous_joker=true, j_fibonacci=true,
    j_even_steven=true, j_odd_todd=true, j_scholar=true, j_walkie_talkie=true,
    j_photograph=true, j_baron=true,
}
local POKER_KEYS = {
    j_jolly=true,j_zany=true,j_mad=true,j_crazy=true,j_droll=true,
    j_sly=true,j_wily=true,j_clever=true,j_devious=true,j_crafty=true,
}
local HAND_ABBREVIATIONS = {
    ['High Card']='ALTA', ['Pair']='PAR', ['Two Pair']='2PAR',
    ['Three of a Kind']='TRIO', ['Straight']='ESC', ['Flush']='COL',
    ['Full House']='FULL', ['Four of a Kind']='POK',
    ['Straight Flush']='ESC+', ['Five of a Kind']='5IG',
    ['Flush House']='FULL+', ['Flush Five']='5COL'
}

-- Dynamic hand preview. Read actual highlighted/played cards; never invent a hand.
-- get_poker_hand_info returns (name, localized_name, poker_hands, scoring_hand, ...).
-- The fourth result is the scoring hand; the third is a map of recognized hands.
local function live_hand()
    if not G or not G.hand or not G.hand.cards then return nil, nil, nil, nil end
    local cards = {}
    if G.play and G.play.cards and #G.play.cards > 0 then
        for _, c in ipairs(G.play.cards) do cards[#cards + 1] = c end
    else
        for _, c in ipairs(G.hand.cards) do
            if c.highlighted then cards[#cards + 1] = c end
        end
    end
    if #cards == 0 then return nil, nil, nil, nil end
    if not (G.FUNCS and type(G.FUNCS.get_poker_hand_info) == 'function') then
        return cards, nil, nil, nil
    end
    -- Never guess which cards score. A pair can be selected with other kickers.
    local ok, name, _, poker_hands, scoring_hand = pcall(G.FUNCS.get_poker_hand_info, cards)
    if not ok or name == 'NULL' or type(scoring_hand) ~= 'table' or type(poker_hands) ~= 'table' then
        return cards, nil, nil, nil
    end
    local actual = {}
    for _, c in ipairs(scoring_hand) do actual[#actual + 1] = c end
    local splash = false
    if G.jokers and G.jokers.cards then
        for _, j in ipairs(G.jokers.cards) do
            if j.config and j.config.center and j.config.center.key == 'j_splash' and not j.debuff then
                splash = true; break
            end
        end
    end
    for _, c in ipairs(cards) do
        local stone = c.config and c.config.center and c.config.center.key == 'm_stone'
        if stone or splash then
            local found = false
            for _, existing in ipairs(actual) do if existing == c then found = true; break end end
            if not found then actual[#actual + 1] = c end
        end
    end
    return cards, actual, poker_hands, name
end

local function dynamic_tag(card, key, a, e)
    local function number(v) return type(v) == 'number' and v or nil end
    local function mult(v) return '+' .. fmt(v), RED end
    local function chips(v) return '+' .. fmt(v), BLUE end
    local hand, scoring = live_hand()
    if key == 'j_raised_fist' and G and G.hand and G.hand.cards and #G.hand.cards > 0 then
        local lowest, id = nil, 99
        for _, c in ipairs(G.hand.cards) do
            if not c.highlighted and c.base and c.base.id and c.base.id <= id
                and c.ability and c.ability.effect ~= 'Stone Card' then
                lowest, id = c, c.base.id
            end
        end
        local value = lowest and not lowest.debuff and lowest.facing ~= 'back'
            and lowest.base.nominal * 2 or 0
        if value > 0 then return mult(value) end
        return nil
    end
    if key == 'j_baron' and G.hand and G.hand.cards then
        local count = 0
        for _, c in ipairs(G.hand.cards) do
            if (not c.highlighted or (G.play and G.play.cards and #G.play.cards > 0))
                and not c.debuff and c.facing ~= 'back' and c.base and c.base.id == 13 then
                count = count + 1
            end
        end
        local base = number(e) or (type(e) == 'table' and (number(e.Xmult) or number(e.x_mult)))
        if base and count > 0 then return 'X' .. fmt(base ^ count), RED end
    end
    -- Scoring-card Jokers: only show the effect for a selected/played hand.
    -- Do not show their base per-card bonus permanently.
    if not scoring then return nil end
    if key == 'j_smiley' or key == 'j_scary_face' then
        local unit = number(e) or (type(e) == 'table' and (number(e.mult) or number(e.chips)))
        if unit then
            local count = 0
            for _, c in ipairs(scoring) do
                if c.is_face and c:is_face() and not c.debuff then count = count + 1 end
            end
            if count > 0 then
                if key == 'j_scary_face' then return chips(unit * count) end
                return mult(unit * count)
            end
        end
        return nil
    end
    -- Poker-hand based Jokers: preview only when a hand is selected.
    -- get_poker_hand_info returns the evaluated poker-hand name in Balatro.
    local hand_name
    if G.FUNCS and type(G.FUNCS.get_poker_hand_info) == 'function' then
        local ok, name = pcall(G.FUNCS.get_poker_hand_info, hand)
        if ok and type(name) == 'string' then hand_name = name end
    end
    if hand_name then
        local need = POKER_HAND_CONDITIONS[key]
        if need then
            local has = (hand_name == need)
            if need == 'Pair' then
                has = has or hand_name == 'Two Pair' or hand_name == 'Full House'
                    or hand_name == 'Three of a Kind' or hand_name == 'Four of a Kind'
                    or hand_name == 'Five of a Kind' or hand_name == 'Flush House'
                    or hand_name == 'Flush Five'
            elseif need == 'Three of a Kind' then
                has = has or hand_name == 'Full House' or hand_name == 'Four of a Kind'
                    or hand_name == 'Five of a Kind' or hand_name == 'Flush House'
                    or hand_name == 'Flush Five'
            elseif need == 'Two Pair' then
                has = has or hand_name == 'Full House' or hand_name == 'Flush House'
            elseif need == 'Straight' then
                has = has or hand_name == 'Straight Flush'
            elseif need == 'Flush' then
                has = has or hand_name == 'Straight Flush' or hand_name == 'Flush House'
                    or hand_name == 'Flush Five'
            end
            local is_chips = key == 'j_sly' or key == 'j_wily' or key == 'j_clever'
                or key == 'j_devious' or key == 'j_crafty'
            local value = is_chips and (number(a.t_chips) or (type(e) == 'table' and number(e.t_chips))) or (number(a.t_mult) or (type(e) == 'table' and number(e.t_mult)))
            if value then
                if not has then return nil end
                if is_chips then return chips(value) end
                return mult(value)
            end
        end
    end
    if key == 'j_photograph' then
        local base = number(e) or (type(e) == 'table' and (number(e.Xmult) or number(e.x_mult)))
        if base then
            local has_face = false
            for _, c in ipairs(scoring) do
                if c.is_face and c:is_face() and not c.debuff then has_face = true; break end
            end
            return 'X' .. fmt(has_face and base or 1), RED
        end
    end
    local suit = SUIT_MULT[key]
    local total = 0
    if suit and (number(e) or (type(e) == 'table' and number(e.s_mult))) then
        for _, c in ipairs(scoring) do
            if not c.debuff and c.is_suit and c:is_suit((type(e) == 'table' and e.suit) or suit) then total = total + (number(e) or e.s_mult) end
        end
        if total > 0 then return mult(total) end
        return nil
    end
    if key == 'j_fibonacci' or key == 'j_even_steven' or key == 'j_odd_todd'
        or key == 'j_scholar' or key == 'j_walkie_talkie' then
        local count = 0
        for _, c in ipairs(scoring) do
            local id = c.get_id and c:get_id() or (c.base and c.base.id)
            if not c.debuff and id then
                local hit = (key == 'j_fibonacci' and (id == 2 or id == 3 or id == 5 or id == 8 or id == 14))
                    or (key == 'j_even_steven' and id <= 10 and id >= 2 and id % 2 == 0)
                    or (key == 'j_odd_todd' and ((id <= 10 and id >= 3 and id % 2 == 1) or id == 14))
                    or (key == 'j_scholar' and id == 14)
                    or (key == 'j_walkie_talkie' and (id == 10 or id == 4))
                if hit then count = count + 1 end
            end
        end
        if key == 'j_scholar' or key == 'j_walkie_talkie' then
            if count > 0 and type(e) == 'table' and number(e.chips) and number(e.mult) then
                return '+' .. fmt(count * e.chips) .. '/+' .. fmt(count * e.mult), BLUE
            end
        elseif number(e) and count > 0 then
            return '+' .. fmt(count * e), key == 'j_odd_todd' and BLUE or RED
        end
    end
    return nil
end

-- Specialized dynamic effects: use live game state, not invented bonuses.
-- Returns handled=true even when the card's label should deliberately be hidden.
local function advanced_tag(card, key, a, e)
    local function num(value) return type(value) == 'number' and value or nil end
    local function x(value) return 'X' .. fmt(value), RED, true end
    local function m(value) return '+' .. fmt(value), RED, true end
    local function c(value) return '+' .. fmt(value), BLUE, true end
    local function money(value) return '+$' .. fmt(value), GOLD, true end
    -- Boolean activation badges: ON only when the checked trigger can occur now.
    local function status(active) return active and 'ON' or 'OFF', active and GREEN or GREY, true end
    local game = G and G.GAME
    local round = game and game.current_round
    local hand, scoring, poker_hands, hand_name = live_hand()
    local jokers = G and G.jokers and G.jokers.cards or {}
    local function key_is(j, which)
        return j and not j.debuff and j.config and j.config.center and j.config.center.key == which
    end
    local function jokers_with(which)
        local amount = 0
        for _, j in ipairs(jokers) do if key_is(j, which) then amount = amount + 1 end end
        return amount
    end
    local function get_id(playing_card)
        if type(playing_card.get_id) == 'function' then return playing_card:get_id() end
        return playing_card.base and playing_card.base.id
    end
    local function is_face(playing_card)
        return type(playing_card.is_face) == 'function' and playing_card:is_face()
    end
    -- Minimal trigger model for non-Blueprint copies, with truthful uncertainty
    -- in probabilistic effects. Red seals / Mime / Sock & Buskin are included.
    local function triggers(playing_card, held)
        if playing_card.debuff then return 0 end
        local amount = 1 + (num(playing_card.ability and playing_card.ability.perma_repetitions) or 0)
        if type(playing_card.get_seal) == 'function' and playing_card:get_seal() == 'Red' then
            amount = amount + 1
        end
        if held then
            amount = amount + jokers_with('j_mime')
        else
            if is_face(playing_card) then amount = amount + jokers_with('j_sock_and_buskin') end
            if jokers_with('j_hack') > 0 then
                local id = get_id(playing_card)
                if id and id >= 2 and id <= 5 then amount = amount + jokers_with('j_hack') end
            end
            if scoring and #scoring > 0 then
                local first_scoring = scoring[1]
                for _, possible in ipairs(scoring) do
                    if possible.T and first_scoring.T and possible.T.x < first_scoring.T.x then
                        first_scoring = possible
                    end
                end
                if playing_card == first_scoring then
                    amount = amount + 2 * jokers_with('j_hanging_chad')
                end
            end
            amount = amount + jokers_with('j_selzer')
            if round and (round.hands_left or 99) <= 1 then
                amount = amount + jokers_with('j_dusk')
            end
        end
        return amount
    end
    local function only_scoring_cards(fn)
        local count = 0
        if not scoring then return 0 end
        for _, pc in ipairs(scoring) do
            if not pc.debuff and pc.facing ~= 'back' and fn(pc) then
                count = count + triggers(pc, false)
            end
        end
        return count
    end
    local function consumable_room()
        local area = G and (G.consumeables or G.consumables)
        if not area or not area.config or not area.cards then return nil end
        local maximum = num(area.config.card_limit)
        if not maximum then return nil end
        return math.max(0, maximum - #area.cards)
    end
    -- Satellite: unique Planet types used this RUN (not the number used).
    if key == 'j_satellite' then
        if game and type(game.consumeable_usage) == 'table' then
            local unique = 0
            for _, usage in pairs(game.consumeable_usage) do
                if type(usage) == 'table' and usage.set == 'Planet' then unique = unique + 1 end
            end
            local per_planet = num(e) or (type(e) == 'table' and num(e.dollars)) or 1
            return money(unique * per_planet)
        end
        return nil, nil, true
    end
    -- Baseball Card: one independent X-mult trigger per Uncommon Joker.
    if key == 'j_baseball' then
        local total = 0
        for _, j in ipairs(jokers) do
            if not j.debuff and j.config and j.config.center and j.config.center.rarity == 2 then
                total = total + 1
            end
        end
        local each = num(e) or (type(e) == 'table' and num(e.Xmult)) or 1.5
        if total > 0 then return x(each ^ total) end
        return 'X1', GREY, true
    end
    -- Shoot the Moon: Queens held in hand, not selected for play.
    if key == 'j_shoot_the_moon' then
        if not (G and G.hand and G.hand.cards) then return nil, nil, true end
        local active = G.play and G.play.cards and #G.play.cards > 0
        local multiplier = num(e) or (type(e) == 'table' and num(e.mult)) or 13
        local amount = 0
        for _, pc in ipairs(G.hand.cards) do
            if (active or not pc.highlighted) and pc.facing ~= 'back' and get_id(pc) == 12 then
                amount = amount + multiplier * triggers(pc, true)
            end
        end
        if amount > 0 then return m(amount) end
        return nil, nil, true
    end
    -- Riff-Raff (La Chusma): remaining capacity for 2 free Common Jokers.
    if key == 'j_riff_raff' then
        local area = G and G.jokers
        if not (area and area.cards and area.config and num(area.config.card_limit)) then return nil,nil,true end
        local free = math.max(0, area.config.card_limit - #area.cards)
        local possible = math.min(num(e) or 2, free)
        return fmt(possible) .. '/2', possible > 0 and GREEN or GREY, true
    end
    -- Bloodstone (Heliotropo): chances per scoring Heart, NOT guaranteed X mult.
    if key == 'j_bloodstone' then
        local times = only_scoring_cards(function(pc)
            return type(pc.is_suit) == 'function' and pc:is_suit('Hearts')
        end)
        if times <= 0 then return nil, nil, true end
        local bonus = type(e) == 'table' and (num(e.Xmult) or num(e.x_mult)) or num(e)
        if bonus then return fmt(times) .. 'xX' .. fmt(bonus) .. '?', RED, true end
        return nil, nil, true
    end
    -- Photograph: X per trigger on FIRST scoring face, not all face cards.
    if key == 'j_photograph' then
        if not scoring then return nil, nil, true end
        local first = nil
        for _, pc in ipairs(scoring) do
            if not pc.debuff and pc.facing ~= 'back' and is_face(pc) then
                if not first or (pc.T and first.T and pc.T.x < first.T.x) then first = pc end
            end
        end
        local mult = num(e) or (type(e) == 'table' and num(e.Xmult))
        if first and mult then return x(mult ^ triggers(first, false)) end
        return nil, nil, true
    end
    -- Seltzer (Refresco): a plain NUMBER in card.ability.extra.
    if key == 'j_selzer' then
        local remaining = num(e) or (type(e) == 'table' and num(e.hands))
        if remaining ~= nil then
            local configured = card.config and card.config.center and card.config.center.config
            local default_e = configured and configured.extra
            card.jokertags_selzer_start = math.max(card.jokertags_selzer_start or 0,
                remaining, num(default_e) or 0, 10)
            return fmt(math.max(0,remaining)) .. '/' .. fmt(card.jokertags_selzer_start),
                remaining > 1 and GREEN or RED, true
        end
        return nil, nil, true
    end
    -- The Duo / Trio / Family / Order / Tribe: uses contained poker hands,
    -- not just the highest-ranking hand name.
    if key == 'j_duo' or key == 'j_trio' or key == 'j_family'
        or key == 'j_order' or key == 'j_tribe' then
        if poker_hands and type(a.type) == 'string' and
            type(poker_hands[a.type]) == 'table' and next(poker_hands[a.type]) then
            local value = num(a.x_mult) or (type(e) == 'table' and num(e.Xmult))
            if value then return x(value) end
        end
        return nil, nil, true
    end
    -- Boolean abilities: always show ON or OFF, never ambiguous status messages.
    -- ON means the current selection meets the trigger conditions as checked
    -- here; OFF can also mean "not currently ready", not permanently disabled.
    if key == 'j_sixth_sense' then
        local room = consumable_room()
        local valid = round and (round.hands_played or 0) == 0
            and room ~= nil and room > 0
            and hand and #hand == 1 and get_id(hand[1]) == 6
        return status(not not valid)
    end
    if key == 'j_seance' then
        local room = consumable_room()
        return status(hand ~= nil and hand_name == 'Straight Flush'
            and room ~= nil and room > 0)
    end
    if key == 'j_dna' then
        return status(round ~= nil and (round.hands_played or 0) == 0
            and hand ~= nil and #hand == 1)
    end
    if key == 'j_trading' or key == 'j_burnt' then
        local first_discard = round ~= nil and (round.discards_used or 0) == 0
            and (round.discards_left or 0) > 0
        local selected = G and G.hand and G.hand.highlighted and #G.hand.highlighted or 0
        if key == 'j_trading' then
            return status(first_discard and selected == 1)
        end
        return status(first_discard and selected > 0)
    end
    if key == 'j_faceless' then
        if round and (round.discards_left or 0) > 0 and G.hand and G.hand.highlighted and type(e) == 'table' then
            local faces = 0
            for _, pc in ipairs(G.hand.highlighted) do
                if pc.facing ~= 'back' and is_face(pc) then faces = faces + 1 end
            end
            if faces >= (num(e.faces) or 3) then
                return money(num(e.dollars) or 5)
            end
        end
        return nil, nil, true
    end
    -- Other independent conditionals that were misleading in the old release.
    if key == 'j_blackboard' then
        if not (G and G.hand and G.hand.cards) then return nil,nil,true end
        local active = G.play and G.play.cards and #G.play.cards > 0
        local valid = true
        for _, pc in ipairs(G.hand.cards) do
            if active or not pc.highlighted then
                if pc.facing == 'back' or type(pc.is_suit) ~= 'function'
                    or not (pc:is_suit('Spades') or pc:is_suit('Clubs')) then
                    valid = false; break
                end
            end
        end
        local bonus = num(e) or (type(e) == 'table' and num(e.Xmult))
        if valid and bonus then return x(bonus) end
        return nil,nil,true
    end
    if key == 'j_acrobat' then
        if not round then return nil,nil,true end
        local playing = G.play and G.play.cards and #G.play.cards > 0
        local last = (not playing and round.hands_left == 1)
            or (playing and round.hands_left == 0)
        local bonus = num(e) or (type(e) == 'table' and num(e.Xmult))
        if last and bonus then return x(bonus) end
        return nil,nil,true
    end
    if key == 'j_seeing_double' then
        if not scoring then return nil,nil,true end
        local club, other, wild = false, false, 0
        for _, pc in ipairs(scoring) do
            if not pc.debuff and type(pc.is_suit) == 'function' then
                if pc.ability and pc.ability.name == 'Wild Card' then
                    wild = wild + 1
                else
                    if pc:is_suit('Clubs') then club = true end
                    if pc:is_suit('Hearts') or pc:is_suit('Spades') or pc:is_suit('Diamonds') then
                        other = true
                    end
                end
            end
        end
        if not club and wild > 0 then club = true; wild = wild - 1 end
        if not other and wild > 0 then other = true end
        local bonus = num(e) or (type(e) == 'table' and num(e.Xmult))
        if club and other and bonus then return x(bonus) end
        return nil,nil,true
    end
    if key == 'j_ancient' or key == 'j_idol' then
        local current = round and round[key == 'j_ancient' and 'ancient_card' or 'idol_card']
        if not current or not current.suit then return nil,nil,true end
        local count = only_scoring_cards(function(pc)
            local same_suit = type(pc.is_suit)=='function' and pc:is_suit(current.suit)
            if key == 'j_idol' then return same_suit and get_id(pc) == current.id end
            return same_suit
        end)
        local bonus = num(e) or (type(e) == 'table' and num(e.Xmult))
        if count > 0 and bonus then return x(bonus^count) end
        return nil,nil,true
    end
    if key == 'j_steel_joker' then
        local tally = num(a.steel_tally)
        local increment = num(e)
        if tally and increment then return x(1 + tally*increment) end
        return nil,nil,true
    end
    if key == 'j_loyalty_card' then
        local count = num(a.loyalty_remaining)
        local every = type(e)=='table' and num(e.every) or nil
        local multiplier = type(e)=='table' and num(e.Xmult) or nil
        if count and every then
            local cycle = every + 1
            local playing = G and G.play and G.play.cards and #G.play.cards > 0
            local next_count = count + (playing and 1 or 0)
            if multiplier and next_count % cycle == 0 then
                return x(multiplier)
            end
            return fmt(next_count % cycle) .. '/' .. fmt(cycle), GREEN, true
        end
        return nil,nil,true
    end
    if key == 'j_invisible' then
        local total = num(e) or (type(e)=='table' and num(e.total)) or 2
        local rounds = num(a.invis_rounds)
        if rounds then
            if rounds >= total then return status(true) end
            return fmt(math.max(0,rounds)) .. '/' .. fmt(total), GREEN, true
        end
        return nil,nil,true
    end
    if key == 'j_luchador' then
        local boss = game and game.blind and type(game.blind.get_type) == 'function'
            and game.blind:get_type() == 'Boss' and not game.blind.disabled
        return status(not not boss)
    end
    if key == 'j_diet_cola' then
        return status(true)
    end
    if key == 'j_rough_gem' or key == 'j_arrowhead' or key == 'j_onyx_agate' then
        local suit = key == 'j_rough_gem' and 'Diamonds'
            or key == 'j_arrowhead' and 'Spades' or 'Clubs'
        local count = only_scoring_cards(function(pc)
            return type(pc.is_suit)=='function' and pc:is_suit(suit)
        end)
        local bonus = num(e)
        if count > 0 and bonus then
            if key == 'j_rough_gem' then return money(count*bonus) end
            if key == 'j_arrowhead' then return c(count*bonus) end
            return m(count*bonus)
        end
        return nil,nil,true
    end
    -- Vanilla JokerDisplay inspired: show a preview only if the hand satisfies
    -- the condition; do not show fabricated permanent multipliers.
    if key == 'j_triboulet' then
        local count = only_scoring_cards(function(pc)
            local id = get_id(pc)
            return id == 12 or id == 13
        end)
        local bonus = num(e) or (type(e) == 'table' and (num(e.Xmult) or num(e.x_mult)))
        if count > 0 and bonus then return x(bonus ^ count) end
        return nil,nil,true
    end
    if key == 'j_flower_pot' then
        if not scoring then return nil,nil,true end
        local suits = {Hearts=false, Diamonds=false, Spades=false, Clubs=false}
        local wild = 0
        for _,pc in ipairs(scoring) do
            if not pc.debuff and pc.facing ~= 'back' and type(pc.is_suit) == 'function' then
                if pc.ability and pc.ability.name == 'Wild Card' then
                    wild = wild + 1
                else
                    for suit in pairs(suits) do
                        if pc:is_suit(suit, true) then suits[suit] = true end
                    end
                end
            end
        end
        local missing = 0
        for _, seen in pairs(suits) do if not seen then missing = missing + 1 end end
        local bonus = num(e) or (type(e)=='table' and (num(e.Xmult) or num(e.x_mult)))
        if missing <= wild and bonus then return x(bonus) end
        return nil,nil,true
    end
    if key == 'j_superposition' then
        local ace_straight = false
        if poker_hands and poker_hands['Straight'] and next(poker_hands['Straight']) and scoring then
            for _,pc in ipairs(scoring) do
                if get_id(pc) == 14 and not pc.debuff then ace_straight = true; break end
            end
        end
        -- An activation indicator is more useful than inventing a Tarot counter.
        return status(ace_straight)
    end
    if key == 'j_mail' then
        local required = round and round.mail_card and round.mail_card.id
        if not required then return nil,nil,true end
        local count = 0
        if round.discards_left and round.discards_left > 0 and G.hand and G.hand.highlighted then
            for _,pc in ipairs(G.hand.highlighted) do
                if not pc.debuff and pc.facing ~= 'back' and get_id(pc) == required then
                    count = count + 1
                end
            end
        end
        local bonus = num(e) or (type(e)=='table' and num(e.dollars))
        if count > 0 and bonus then return money(count * bonus) end
        return nil,nil,true
    end
    -- Conditions translated from JokerDisplay vanilla definitions.
    if key == 'j_todo_list' then
        local target = a.to_do_poker_hand
        local dollars = type(e)=='table' and num(e.dollars) or num(e)
        if hand_name and target and hand_name == target and dollars then
            return money(dollars)
        end
        return nil,nil,true
    end
    if key == 'j_vagabond' then
        return status(game and type(game.dollars)=='number' and game.dollars <= 4)
    end
    if key == 'j_reserved_parking' then
        if not G.hand or not G.hand.cards then return nil,nil,true end
        local playing = G.play and G.play.cards and #G.play.cards > 0
        local count = 0
        for _,pc in ipairs(G.hand.cards) do
            if (playing or not pc.highlighted) and not pc.debuff
                and pc.facing ~= 'back' and is_face(pc) then
                count = count + triggers(pc, true)
            end
        end
        local bonus = type(e)=='table' and num(e.dollars) or num(e)
        if count > 0 and bonus then
            return fmt(count) .. 'x$' .. fmt(bonus) .. '?', GOLD, true
        end
        return nil,nil,true
    end
    if key == 'j_ticket' then
        local count = only_scoring_cards(function(pc)
            return pc.ability and pc.ability.name == 'Gold Card'
        end)
        local bonus = num(e) or (type(e)=='table' and num(e.dollars))
        if count > 0 and bonus then return money(count * bonus) end
        return nil,nil,true
    end
    if key == 'j_mr_bones' then
        local blind = game and game.blind
        local score = game and num(game.chips)
        local target = blind and num(blind.chips)
        -- Only check a current blind; the 25% threshold alone is sufficient
        -- but does not guarantee survival against special blind mechanics.
        local in_blind = blind and blind.in_blind
        return status(not not (in_blind and score and target and target > 0
            and score >= 0.25 * target))
    end
    if key == 'j_chicot' then
        local blind = game and game.blind
        return status(not not (blind and type(blind.get_type)=='function'
            and blind:get_type() == 'Boss'))
    end
    -- Business Card: each qualifying scoring face gives one chance to earn $.
    if key == 'j_business' then
        local count = only_scoring_cards(function(pc) return is_face(pc) end)
        local denominator = num(e) or (type(e)=='table' and num(e.odds))
        if count > 0 and denominator then
            local numerator = game and game.probabilities and num(game.probabilities.normal) or 1
            return fmt(count) .. 'x' .. fmt(numerator) .. '/' .. fmt(denominator) .. '?', GREEN, true
        end
        return nil, nil, true
    end
    -- Space Joker only has an upgrade chance when a hand is being played.
    if key == 'j_space' then
        local denominator = num(e) or (type(e)=='table' and num(e.odds))
        if hand and denominator then
            local numerator = game and game.probabilities and num(game.probabilities.normal) or 1
            return fmt(numerator) .. '/' .. fmt(denominator) .. '?', GREEN, true
        end
        return nil, nil, true
    end
    -- Matador can trigger only during an enabled Boss Blind, and only if the
    -- specific boss effect activates. ON is availability, NOT promised money.
    if key == 'j_matador' then
        local blind = game and game.blind
        local eligible = blind and type(blind.get_type)=='function'
            and blind:get_type()=='Boss' and not blind.disabled
        return status(not not eligible)
    end
    -- 8 Ball: only when an 8 is going to score; probability is not +Mult.
    if key == 'j_8_ball' then
        local number_of_eights = only_scoring_cards(function(pc) return get_id(pc) == 8 end)
        if number_of_eights > 0 then
            return fmt(number_of_eights) .. 'x?', GREEN, true
        end
        return nil, nil, true
    end
    return nil, nil, false
end

local function tag(card, depth)
    local a = card.ability or {}
    local e = a.extra
    local key = card.config and card.config.center and card.config.center.key
    local game = G and G.GAME
    local round = game and game.current_round
    if (key == 'j_blueprint' or key == 'j_brainstorm') and (depth or 0) < 5 then
        local area = G and G.jokers and G.jokers.cards
        if area then
            local copied
            if key == 'j_brainstorm' then copied = area[1]
            else
                for i,j in ipairs(area) do
                    if j == card then copied = area[i+1]; break end
                end
            end
            if copied and copied ~= card and not copied.debuff
                and copied.config and copied.config.center
                and copied.config.center.blueprint_compat ~= false then
                return tag(copied, (depth or 0) + 1)
            end
        end
        return nil,nil
    end
    local special_text, special_colour, special_handled = advanced_tag(card, key, a, e)
    if special_handled then return special_text, special_colour end
    local dynamic_text, dynamic_colour = dynamic_tag(card, key, a, e)
    if dynamic_text then return dynamic_text, dynamic_colour end
    if HAND_ONLY[key] then return nil, nil end
    local function n(v) return type(v) == 'number' and v or nil end
    local function plus(v, colour) if n(v) then return '+' .. fmt(v), colour end end
    local function xmult(v) if n(v) then return 'X' .. fmt(v), RED end end

    -- Canio: unique stored Xmult. Generic ability.x_mult can stay at X1,
    -- and must never take precedence over the actual destroyed-face tally.
    if key == 'j_caino' then
        local value = n(a.caino_xmult)
        if value then return xmult(value) end
        return nil, nil
    end

    -- Driver's License reads its built-in enhanced-card tally when available.
    -- Balatro stores the X3 amount as a NUMERIC ability.extra, not extra.Xmult.
    if key == 'j_drivers_license' then
        local enhanced = n(a.driver_tally)
        if enhanced == nil and G and G.playing_cards then
            enhanced = 0
            for _, pc in ipairs(G.playing_cards) do
                local center = pc.config and pc.config.center
                if center and center.set == 'Enhanced' then
                    enhanced = enhanced + 1
                end
            end
        end
        local required = 16
        local amount = n(e) or (type(e)=='table' and (n(e.Xmult) or n(e.x_mult)))
            or (card.config and card.config.center and card.config.center.config
                and n(card.config.center.config.extra))
        if enhanced and enhanced >= required and amount then return xmult(amount) end
        return nil, nil
    end

    -- Turtle Bean is NOT the Perishable sticker. Its hand-size bonus decays.
    -- Keep the starting bonus, just like JokerDisplay's start_count.
    if key == 'j_turtle_bean' and type(e) == 'table' and n(e.h_size) then
        local current = math.max(0, e.h_size)
        local original = card.config and card.config.center and card.config.center.config
        local initial = original and original.extra and n(original.extra.h_size)
        card.jokertags_bean_start = math.max(card.jokertags_bean_start or 0, current, initial or 0)
        return fmt(current) .. '/' .. fmt(card.jokertags_bean_start), GREEN
    end

    -- Gros Michel: its +Mult is a fixed active effect, not an accumulated tally.
    -- Some versions leave ability.mult at zero while the card is still alive.
    if key == 'j_gros_michel' then
        local configured = card.config and card.config.center and card.config.center.config
        local configured_extra = configured and configured.extra
        local bonus = (type(e) == 'table' and n(e.mult))
            or (type(e) == 'number' and e)
            or (type(configured_extra) == 'table' and n(configured_extra.mult))
            or (type(configured_extra) == 'number' and configured_extra)
            or n(a.mult)
        if bonus and bonus > 0 then return plus(bonus, RED) end
        return nil, nil
    end
    -- Cavendish keeps a static X multiplier in extra.Xmult.
    if key == 'j_cavendish' and type(e)=='table' and n(e.Xmult) then
        return xmult(e.Xmult)
    end
    -- Vanilla card values, matching the corresponding JokerDisplay definitions.
    if DIRECT_XMULT[key] then
        local v = n(a.x_mult) or n(a.caino_xmult) or (type(e) == 'table' and (n(e.Xmult) or n(e.x_mult)))
        if v then return xmult(v) end
    end
    if DIRECT_MULT[key] then
        local v = n(a.mult) or (type(e) == 'table' and n(e.mult))
        if v then return plus(v, RED) end
    end
    if DIRECT_CHIPS[key] and type(e) == 'table' then
        local v = n(e.chips) or n(e.chip_mod)
        if v then return plus(v, BLUE) end
    end
    -- Half Joker activates only when playing 3 or fewer cards.
    if key == 'j_half' then
        local hand = live_hand()
        local bonus = type(e) == 'table' and n(e.mult) or n(e)
        if hand and #hand <= 3 and bonus then return plus(bonus, RED) end
        return nil, nil
    end
    if key == 'j_banner' and n(e) and round then
        return plus(e * (round.discards_left or 0), BLUE)
    end
    if key == 'j_blue_joker' then
        local per_card = n(e) or (type(e) == 'table' and n(e.chips))
        local deck_count = G.deck and G.deck.cards and #G.deck.cards
        if per_card and deck_count then return plus(per_card * deck_count, BLUE) end
    end
    if key == 'j_mystic_summit' and type(e) == 'table' and round and n(e.mult) and n(e.d_remaining) then
        if round.discards_left <= e.d_remaining then return plus(e.mult, RED) end
        return nil, nil
    end
    if key == 'j_stone' and n(e) then return plus(e * (a.stone_tally or 0), BLUE) end
    if key == 'j_golden' and n(e) then return '+$' .. fmt(e), GOLD end
    if key == 'j_egg' and n(card.sell_cost) then return '$' .. fmt(card.sell_cost), GOLD end
    if key == 'j_fortune_teller' and game then
        local count = game.consumeable_usage_total and game.consumeable_usage_total.tarot or 0
        return plus(count, RED)
    end
    if key == 'j_rocket' and type(e) == 'table' and n(e.dollars) then return '+$' .. fmt(e.dollars), GOLD end
    -- Bull/Erosion use numeric extra in vanilla Balatro, not tables.
    if key == 'j_bull' and game and n(game.dollars) then
        local each = n(e) or (type(e)=='table' and n(e.chips))
        if each then return plus(each * math.max(0,game.dollars), BLUE) end
    end
    if key == 'j_erosion' and G.playing_cards and game and n(game.starting_deck_size) then
        local each = n(e) or (type(e)=='table' and n(e.mult))
        if each then
            return plus(math.max(0,each*(game.starting_deck_size-#G.playing_cards)),RED)
        end
    end

    -- Extra vanilla Jokers: live values or calculated state.
    if key == 'j_abstract' and G.jokers and G.jokers.cards then
        local per_joker = n(e) or (type(e) == 'table' and n(e.mult))
        if per_joker then return plus(per_joker * #G.jokers.cards, RED) end
    end
    if key == 'j_delayed_grat' and type(e) == 'table' and n(e.dollars) and round then
        return '+$' .. fmt((round.discards_used == 0 and (round.discards_left or 0) > 0) and e.dollars * round.discards_left or 0), GOLD
    end
    if key == 'j_supernova' and game and game.hands then
        local selected, _, _, evaluated_name = live_hand()
        local played = evaluated_name and game.hands[evaluated_name] and n(game.hands[evaluated_name].played)
        if played then
            local now_playing = G and G.play and G.play.cards and #G.play.cards > 0
            return plus(played + (now_playing and 0 or 1), RED)
        end
        return nil, nil
    end
    if key == 'j_cloud_9' and (n(e) or (type(e) == 'table' and n(e.dollars))) and G.playing_cards then
        local count = 0
        for _, c in ipairs(G.playing_cards) do
            if c.base and c.base.id == 9 and not (c.debuff) then count = count + 1 end
        end
        return '+$' .. fmt(count * (n(e) or e.dollars)), GOLD
    end
    if key == 'j_to_the_moon' and n(e) and game and n(game.dollars) then
        local cap = n(game.interest_cap) or 25
        return '+$' .. fmt(math.max(0, math.min(math.floor(game.dollars / 5), math.floor(cap / 5))) * e), GOLD
    end
    if key == 'j_bootstraps' and type(e) == 'table' and game and n(game.dollars) then
        local amount = n(e.mult) or n(e.mult_mod)
        local step = n(e.dollars) or n(e.dollars_per_mult) or 5
        if amount and step > 0 then return plus(math.floor(math.max(0, game.dollars) / step) * amount, RED) end
    end
    if key == 'j_credit_card' and type(e) == 'table' then
        local limit = n(e.dollars) or n(e.limit) or 20
        return '-$' .. fmt(limit), GOLD
    end
    if key == 'j_burglar' and type(e) == 'table' and n(e.hands) then return '+' .. fmt(e.hands), GREEN end
    if key == 'j_juggler' and n(e) then return '+' .. fmt(e), GREEN end
    if key == 'j_drunkard' and n(e) then return '+' .. fmt(e), GREEN end
    if key == 'j_troubadour' and type(e) == 'table' and n(e.h_size) then return '+' .. fmt(e.h_size), GREEN end
    if key == 'j_merry_andy' and type(e) == 'table' and n(e.discards) then return '+' .. fmt(e.discards), GREEN end
    if key == 'j_joker' and n(a.mult) then return plus(a.mult, RED) end


    -- Hand-dependent Jokers must never fall back to a permanent bonus.
    if POKER_KEYS[key] then return nil, nil end
    -- Misprint is the only reachable case of the legacy static-bonus table.
    if key == 'j_misprint' and type(e) == 'table' and n(e.max) then
        local low = n(e.min) or 0
        return fmt(low) .. '-' .. fmt(e.max), RED
    end
    -- Card Sharp is conditional; do not show a permanent X multiplier.
    if key == 'j_card_sharp' then
        local _, _, _, poker_name = live_hand()
        local already_played = poker_name and game and game.hands and game.hands[poker_name] and (game.hands[poker_name].played or 0) > 0
        local bonus = type(e) == 'table' and (n(e.Xmult) or n(e.x_mult)) or n(e)
        if already_played and bonus then return xmult(bonus) end
        return nil, nil
    end
    -- Perishable and rental are separate stickers, not Joker effects.
    -- Prefer the main effect; display a sticker if no primary value exists.
    local remaining = n(a.perish_tally)
    if a.perishable or remaining ~= nil then
        local total = game and n(game.perishable_rounds) or 5
        if total <= 0 then total = 5 end
        if remaining ~= nil then return fmt(math.max(0, remaining)) .. '/' .. fmt(total), GREY end
        return 'PEREC.', GREY
    end
    if a.rental then return '-$' .. fmt(game and game.rental_rate or 3), GOLD end
    return nil, nil
end

-- Editions are independent of the Joker's own scoring ability.
-- Negative changes capacity, not scoring; intentionally no numeric badge.
local function edition_tag(card)
    local e = card.edition
    if type(e) ~= 'table' then return nil, nil, false end
    if e.polychrome then return 'X' .. fmt(tonumber(e.x_mult) or 1.5), {0.65,0.36,0.86,1}, true end
    if e.holo then return '+' .. fmt(tonumber(e.mult) or 10), RED, false end
    if e.foil then return '+' .. fmt(tonumber(e.chips) or 50), BLUE, false end
    return nil, nil, false
end

-- Suit symbols are drawn as tiny geometric icons, not Unicode text.
-- Balatro's pixel font may lack suit/emoji glyphs, especially on Android.
local SUIT_HINTS = {
    j_greedy_joker='Diamonds', j_lusty_joker='Hearts',
    j_wrathful_joker='Spades', j_gluttenous_joker='Clubs',
    j_rough_gem='Diamonds', j_arrowhead='Spades',
    j_onyx_agate='Clubs', j_bloodstone='Hearts',
}
local function suit_hint(card)
    local key = card.config and card.config.center and card.config.center.key
    if key == 'j_ancient' or key == 'j_idol' then
        local r = G and G.GAME and G.GAME.current_round
        local target = r and r[key == 'j_ancient' and 'ancient_card' or 'idol_card']
        return target and target.suit
    end
    return SUIT_HINTS[key]
end
local function draw_suit_symbol(suit, cx, cy, d)
    -- Shapes use the same drawing transform as the badge.
    if suit == 'Hearts' then
        love.graphics.circle('fill', cx-d*0.19, cy-d*0.14, d*0.24, 10)
        love.graphics.circle('fill', cx+d*0.19, cy-d*0.14, d*0.24, 10)
        love.graphics.polygon('fill',cx-d*0.42,cy-d*0.11,cx+d*0.42,cy-d*0.11,cx,cy+d*0.49)
    elseif suit == 'Diamonds' then
        love.graphics.polygon('fill',cx,cy-d*0.49,cx+d*0.37,cy,cx,cy+d*0.49,cx-d*0.37,cy)
    elseif suit == 'Spades' then
        love.graphics.polygon('fill',cx,cy-d*0.49,cx+d*0.43,cy+d*0.14,cx-d*0.43,cy+d*0.14)
        love.graphics.circle('fill',cx-d*0.19,cy+d*0.09,d*0.24,10)
        love.graphics.circle('fill',cx+d*0.19,cy+d*0.09,d*0.24,10)
        love.graphics.rectangle('fill',cx-d*0.07,cy+d*0.12,d*0.14,d*0.33)
    elseif suit == 'Clubs' then
        love.graphics.circle('fill',cx,cy-d*0.24,d*0.24,10)
        love.graphics.circle('fill',cx-d*0.23,cy+d*0.10,d*0.25,10)
        love.graphics.circle('fill',cx+d*0.23,cy+d*0.10,d*0.25,10)
        love.graphics.rectangle('fill',cx-d*0.07,cy+d*0.09,d*0.14,d*0.37)
    end
end

local function short_hint(card)
    local key = card.config and card.config.center and card.config.center.key
    local round = G and G.GAME and G.GAME.current_round
    if key == 'j_mail' then
        local target = round and round.mail_card
        local id = target and target.id
        if id == 14 then return 'A', GOLD end
        if id == 13 then return 'K', GOLD end
        if id == 12 then return 'Q', GOLD end
        if id == 11 then return 'J', GOLD end
        if type(id)=='number' then return fmt(id), GOLD end
    elseif key == 'j_todo_list' then
        local target = card.ability and card.ability.to_do_poker_hand
        if target then return HAND_ABBREVIATIONS[target] or '?', GOLD end
    end
    return nil,nil
end

local function draw_tag(card, text, colour, other_text, other_colour, rainbow, suit)
    local font = G and G.LANG and G.LANG.font
    if not font or not font.FONT or not G.TILESIZE or not prep_draw then return end
    local tile = G.TILESIZE
    local w, h = card.T.w, card.T.h
    if not w or not h then return end
    local bw, bh = math.min(w * 0.94, 0.98), 0.33
    local y = h + 0.025
    local dual = (text ~= nil or suit ~= nil) and other_text ~= nil
    -- When there are two effects, both fit within the card's original badge width.
    local gap = 0.025
    local widths = dual and {(bw-gap)/2, (bw-gap)/2} or {bw}
    -- Reuse Love2D Text objects. Creating & releasing GPU text on every
    -- Card:draw() call caused unnecessary work on Android.
    local glyph_cache = card.jokertags_mobile_textcache    if not glyph_cache then
        glyph_cache = {}
        card.jokertags_mobile_textcache = glyph_cache
    end
    local items = {}
    if text ~= nil or suit ~= nil then items[#items+1] = {text or '', colour or GREY, false, suit} end
    if other_text then items[#items+1] = {other_text, other_colour, rainbow} end
    if #items == 0 then return end
    prep_draw(card, 1)
    local x = (w-bw)/2
    for i, item in ipairs(items) do
        local label, base, is_rainbow, item_suit = item[1], item[2], item[3], item[4]
        local width = widths[i] or bw
        local fw = label ~= '' and font.FONT:getWidth(label) * font.squish * font.FONTSCALE / tile or 0
        local fh = font.FONT:getHeight() * font.FONTSCALE * font.TEXT_HEIGHT_SCALE / tile
        if (fw > 0 or item_suit) and fh > 0 then
            local icon_space = item_suit and bh*0.67 or 0
            local scale = math.min((width*0.88-icon_space)/math.max(fw,0.001),
                (bh*0.82)/fh, 0.56)
            scale = math.max(0.08, scale)
            local tw, th = fw*scale, fh*scale
            local fill = base
            if is_rainbow then
                local t = (love.timer and love.timer.getTime and love.timer.getTime() or 0)*1.8
                fill = {0.57+0.24*math.sin(t), 0.45+0.21*math.sin(t+2.094), 0.65+0.23*math.sin(t+4.188), 1}
            end
            love.graphics.setColor(0.09,0.12,0.15,1)
            love.graphics.rectangle('fill',x-0.018,y+0.02,width+0.036,bh+0.015,0.04,0.04)
            love.graphics.setColor(fill)
            love.graphics.rectangle('fill',x,y,width,bh,0.04,0.04)
            love.graphics.setColor(1,1,1,1)
            local tx = x+(width-(tw+icon_space))/2+icon_space+font.TEXT_OFFSET.x*scale*font.FONTSCALE/tile
            local ty = y+(bh-th)/2+font.TEXT_OFFSET.y*scale*font.FONTSCALE/tile
            if item_suit then
                love.graphics.setColor(1, 1, 1, 1)
                local icon_cx = x+(width-(tw+icon_space))/2+icon_space*0.47
                draw_suit_symbol(item_suit, icon_cx, y+bh*0.52, bh*0.52)
            end
            if fw > 0 then
                local cached = glyph_cache[i]
                if not cached or cached.label ~= label or cached.font ~= font.FONT then
                    if cached and cached.drawable and cached.drawable.release then
                        cached.drawable:release()
                    end
                    cached = {label = label, font = font.FONT,
                        drawable = love.graphics.newText(font.FONT,tostring(label))}
                    glyph_cache[i] = cached
                end
                love.graphics.draw(cached.drawable,tx,ty,0,
                    scale*font.squish*font.FONTSCALE/tile,scale*font.FONTSCALE/tile)
            end
        end
        x=x+width+gap
    end
    love.graphics.pop()
end

local previous_draw = Card.draw
function Card:draw(...)
    local result = previous_draw(self, ...)
    if G and G.jokers and self.area == G.jokers and self.facing ~= 'back'
        and self.states and self.states.visible ~= false and self.T and not self.debuff then
        local ok, text, colour = pcall(tag, self)
        if not ok then
            if not self.jokertags_error_logged then
                self.jokertags_error_logged = true
                print('[JokerTagsMobile] skip tag: ' .. tostring(text))
            end
            text, colour = nil, nil
        end
        local edition_text, edition_colour, rainbow = edition_tag(self)
        local suit = suit_hint(self)
        if not text then text, colour = short_hint(self) end
        if text or edition_text or suit then
            draw_tag(self, text, colour, edition_text, edition_colour, rainbow, suit)
        end
    end
    return result
end