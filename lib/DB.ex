defmodule DB do


  @type key :: String.t

  defmodule Variant do
    @type t :: %Variant{
      name: String.t,
      allocation: number,
      is_control: boolean,
      description: String.t,
      payload: String.t
    }

    @enforce_keys [:name, :allocation, :is_control]
    @other_keys [:description, :payload]

    defstruct @enforce_keys ++ @other_keys
  end

  defmodule Experiment do
    #@TODO: add exclusion field
    @type t :: %Experiment{
      name: String.t,
      sampling: float,
      variants: list(Variant.t),

      start_date: DateTime,
      end_date: DateTime,

      description: String.t,
      tags: list(String.t),
      created_date: DateTime,
      updated_date: DateTime,

    }

    @enforce_keys [:name, :sampling, :variants, :start_date, :end_date]
    @other_keys [:description, :tags, :created_date, :updated_date]

    defstruct @enforce_keys ++ @other_keys
   end

   defmodule Exclusion do
     @type t :: %Exclusion{
       experiment_name: String.t,
       excluded_experiments: MapSet.t(String.t)
     }
     @enforce_keys [:experiment_name, :excluded_experiments]
     @other_keys []

     defstruct @enforce_keys ++ @other_keys
   end

   defmodule Allocation do
     @type t :: %Allocation{
       hash_id: String.t,
       user_id: String.t,
       experiment_name: String.t,
       variant: String.t,
       allocation_date: DateTime
     }

     @enforce_keys [:hash_id, :user_id, :experiment_name, :variant, :allocation_date]
     @other_keys []

     defstruct @enforce_keys ++ @other_keys
   end


  def create_tables do
    :lbm_kv.create(Experiment)
    :lbm_kv.create(Exclusion)
    :lbm_kv.create(Allocation)
  end


  def get_hash(s) do
    :crypto.hash(:md5, s) |> Base.encode16() |> String.downcase()
  end

  ## EXPERIMENT
  @spec put_experiment(Experiment.t) :: {:ok, [{key(), Experiment.t}]} | {:error, any()}
  def put_experiment(exp) do
    :lbm_kv.put(Experiment, exp.name, exp)

    #@TODO: manage exclusion as well... or NOT: exclusion is not XP attribute!!
  end

  @spec get_experiment(key()) :: {:ok, [{key(), Experiment.t}]} | {:error, any()}
  def get_experiment(exp_name) do
    :lbm_kv.get(Experiment, exp_name)
  end

  @spec del_experiment(key() | [key()]) :: {:ok, [{key(), Experiment.t}]} | {:error, any()}
  def del_experiment(key_or_keys) do
    :lbm_kv.del(Experiment, key_or_keys)

    #@TODO: remove exclusions as well
  end

  ## EXCLUSION
  @spec put_exclusion(Experiment.t, Experiment.t) :: {:ok, [{key(), Exclusion.t}]} | {:error, any()}
  def put_exclusion(exp_a, exp_b) do
    ex_AB = do_generate_exclusion(exp_a, exp_b)
    ex_BA = do_generate_exclusion(exp_b, exp_a)
    :lbm_kv.put(Exclusion, [{ex_AB.experiment_name, ex_AB}, {ex_BA.experiment_name, ex_BA}])
  end

  @spec do_generate_exclusion(Experiment.t, Experiment.t) :: Exclusion.t | {:error, any()}
  defp do_generate_exclusion(exp_a, exp_b) do
    new_exclusions = case get_exclusion(exp_a.name) do
                       {:ok, [_, excl]} -> excl.excluded_experiments
                       _ -> MapSet.new
                     end
                     |> MapSet.put(exp_b.name)

    %Exclusion{
      experiment_name: exp_a.name,
      excluded_experiments: new_exclusions
    }
  end

  @spec get_exclusion(key()) :: {:ok, [{key(), Exclusion.t}]} | {:error, any()}
  def get_exclusion(exp_name) do
    :lbm_kv.get(Exclusion, exp_name)
  end

  @spec del_exclusion(Experiment.t, Experiment.t) :: {:ok, {key(), key()}} | {:error, any()}
  def del_exclusion(exp_a, exp_b) do
    ex_AB = do_remove_exclusion(exp_a, exp_b)
    ex_BA = do_remove_exclusion(exp_b, exp_a)
    :lbm_kv.put(Exclusion, [{ex_AB.experiment_name, ex_AB}, {ex_BA.experiment_name, ex_BA}])
  end

  @spec do_remove_exclusion(Experiment.t, Experiment.t) :: Exclusion.t | {:error, any()}
  def do_remove_exclusion(exp_a, exp_b) do
    new_exclusions = case get_exclusion(exp_a.name) do
                       {:ok, [_, excl]} -> excl.excluded_experiments
                       _ -> MapSet.new
                     end
                     |> MapSet.delete(exp_b.name)

    %Exclusion{
      experiment_name: exp_a.name,
      excluded_experiments: new_exclusions
    }
  end


  ## ALLOCATION
  @spec put_allocation(String.t, Experiment.t) :: {:ok, [{key(), Allocation.t}]} | {:error, any()}
  def put_allocation(user_id, exp) do
    ## @type t :: %Allocation{
    ##   hash_id: String.t,
    ##   user_id: String.t,
    ##   experiment_name: String.t,
    ##   variant: String.t,
    ##   allocation_date: DateTime
    ## }

    #@TODO:
    alloc_variant = "variant_name"
    ## alloc_type = "NEW_ASSIGNMENT"

    hash_id = "#{user_id}#{exp.name}" |> get_hash

    alloc = %Allocation{
      hash_id: hash_id,
      user_id: user_id,
      experiment_name: exp.name,
      variant: alloc_variant,
      allocation_date: DateTime.utc_now
    }

    :lbm_kv.put(Allocation, hash_id, alloc)
  end

  @spec get_allocation(key(), Experiment.t) :: {:ok, [{key(), Allocation.t}]} | {:error, any()}
  def get_allocation(user_id, exp) do
    hash_id = "#{user_id}#{exp.name}" |> get_hash
    :lbm_kv.get(Allocation, hash_id)
  end

  @spec del_allocation(key() | [key()]) :: {:ok, [{key(), Allocation.t}]} | {:error, any()}
  def del_allocation(key_or_keys) do
    :lbm_kv.del(Allocation, key_or_keys)
  end

end
