defmodule Timesup.Repo.Migrations.AddAllFields do
  use Ecto.Migration

  def up do
    alter table("games") do
      add(:player_stack, :map, default: fragment("'{}'::jsonb"))
      add(:playing, :boolean, default: false)
      add(:time_remaining, :integer, default: 30)
      add(:show_round_intro, :boolean, default: true)
      add(:last_card_guessed, :string, default: nil)
    end

    execute("UPDATE games SET player_stack = teams;")
  end

  def down do
    alter table("games") do
      remove(:player_stack, :map, default: fragment("'{}'::jsonb"))
      remove(:playing, :boolean, default: false)
      remove(:time_remaining, :integer, default: 30)
      remove(:show_round_intro, :boolean, default: true)
      remove(:last_card_guessed, :string, default: nil)
    end
  end
end
