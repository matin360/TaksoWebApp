defmodule Takso.Repo.Migrations.UsersDropUsernameCreateEmail do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :username, :string
      add :email, :string
      add :age, :integer
    end
  end
end
