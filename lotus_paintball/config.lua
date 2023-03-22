Config = {}
Config.locale = 'en'

Config.Discord = {
  WebhookURL = "DISCORD_WEBHOOK",
  AvatarURL = "WEBHOOK_IMAGE_URL",
  Username = "Paintball",
}

Config.Paintball = {
  Field = {
    x = -84.24, y = -821.98, z = 36.03, Blip = 313, Color = 2, Name = "Lotus Paintball Field", -- blip
    Exit = { x = 2017.44, y = 2786.73, z = 49.3, r = 255, g = 155, b = 0, a = 100, m = 1 }, -- End Match marker
  },
  Teams = {
    {
      Name = "Red", Blip = 1, Color = 1,
      m = 1, x = -86.01, y = -815.3, z = 35.07, r = 244, g = 67, b = 54, a = 155, -- Team entrance
      m2 = 21, x2 = 2023.1, y2 = 2848.09, z2 = 50.68, r2 = 244, g2 = 67, b2 = 54, a2 = 100, -- Team spawn / ready
    },
    {
      Name = "Blue", Blip = 1, Color = 3,
      m = 1, x = -80.47, y = -816.43, z = 35.08, r = 30, g = 144, b = 255, a = 155, -- Team entrance
      m2 = 21, x2 = 2018.6, y2 = 2716.74, z2 = 50.37, r2 = 30, g2 = 144, b2 = 255, a2 = 100, -- Team spawn / ready
    },
  },
  ScoreGoal = 50, -- First team to score this amount of points wins
  RespawnTime = 5, -- Cooldown time in seconds to auto-respawn
  EntranceFee = 50000, -- 5k per round. 10 rounds per match
}
