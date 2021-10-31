defmodule Takso.Repo.Migrations.AddRoleToTheUserTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_customer, :boolean
    end
  end
end
