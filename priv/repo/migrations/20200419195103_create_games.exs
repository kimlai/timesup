defmodule Timesup.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:status, :string)
      add(:players, :map)
      add(:round, :string)
      add(:deck, {:array, :string})

      timestamps()
    end
  end
end
