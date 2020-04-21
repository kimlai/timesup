defmodule Timesup.Repo.Migrations.AddTeams do
  use Ecto.Migration

  def change do
    alter table("games") do
      add(:teams, :map)
    end
  end
end
