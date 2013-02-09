module KnifeBoxer
  class ConstraintUpdate < Struct.new(:name, :old_constraint, :new_constraint)

    def old_version
      if old_constraint.nil?
        "Nothing"
      else
        old_constraint.sub(/^= /, '')
      end
    end

    def new_version
      new_constraint.sub(/^= /, '')
    end

    def description(name_justify=0)
      "#{name.ljust(name_justify)} #{old_version} => #{new_version}"
    end
  end
end

