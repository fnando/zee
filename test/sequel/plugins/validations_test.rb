# frozen_string_literal: true

require "test_helper"

class ValidationsTest < Minitest::Test
  def create_model(&)
    db = Sequel.connect("sqlite::memory:")
    db.execute <<~SQL
      CREATE TABLE users (
        id integer primary key not null,
        a integer not null,
        b integer not null
      )
    SQL

    Class.new(Sequel::Model(db[:users])) do
      def self.name
        "Models::User"
      end

      plugin :validations
      self.strict_param_setting = false
      class_eval(&) if block_given?
    end
  end

  test "translates exact validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            c: {
              exact_length: {
                one: "length is not %{count}",
                other: "length is not %{count}"
              }
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b, :c

      def validate
        super
        validates_exact_length(1, :a)
        validates_exact_length(2, :b)
        validates_exact_length(3, :c)
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a],
                    "must have exactly one character"
    assert_includes record.tap(&:valid?).errors[:b],
                    "must have exactly 2 characters"
    assert_includes record.tap(&:valid?).errors[:c],
                    "length is not 3"
  end

  test "translates format validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            url: {
              format: "must be a valid url"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :url

      def validate
        super
        validates_format(/\Aa+\z/, :a)
        validates_format(%r{\Ahttps?://}, :url)
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a],
                    "is invalid"
    assert_includes record.tap(&:valid?).errors[:url],
                    "must be a valid url"
  end

  test "translates includes validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            status: {
              includes: "should be either 1, 2 or 3"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :status

      def validate
        super
        validates_includes([1, 2, 3], :a)
        validates_includes(%w[approved pending blocked], :status)
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a],
                    "must be one of [1, 2, 3]"
    assert_includes record.tap(&:valid?).errors[:status],
                    "should be either 1, 2 or 3"
  end

  test "translates integer validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              integer: "should be a number"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_integer(%i[a b])
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a],
                    "is not a number"
    assert_includes record.tap(&:valid?).errors[:b],
                    "should be a number"
  end

  test "translates numeric validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              numeric: "should be a number"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_numeric(%i[a b])
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a],
                    "is not a number"
    assert_includes record.tap(&:valid?).errors[:b],
                    "should be a number"
  end

  test "translates length range validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              length_range:
                "must have between %{lower}-%{upper} characters"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_length_range(1..3, %i[a b])
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a],
                    "must have between 1 and 3 characters"
    assert_includes record.tap(&:valid?).errors[:b],
                    "must have between 1-3 characters"
  end

  test "translates max length validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              max_length: {
                one: "should have up to 1 character",
                other: "should have up to %{count} characters"
              },
              not_present: "should be set"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_max_length(3, %i[a b])
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a], "is required"
    assert_includes record.tap(&:valid?).errors[:b], "should be set"

    record = model.new(a: "a" * 5, b: "a" * 10)

    assert_includes record.tap(&:valid?).errors[:a],
                    "must be have up to 3 characters"
    assert_includes record.tap(&:valid?).errors[:b],
                    "should have up to 3 characters"
  end

  test "translates min length validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              min_length: {
                one: "should have at least 1 character",
                other: "should have at least %{count} characters"
              },
              not_present: "should be set"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_min_length(10, %i[a b])
      end
    end

    record = model.new(a: "a" * 1, b: "a" * 2)

    assert_includes record.tap(&:valid?).errors[:a],
                    "must be have at least 10 characters"
    assert_includes record.tap(&:valid?).errors[:b],
                    "should have at least 10 characters"
  end

  test "translates max value validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              max_value: {
                one: "should be smaller than %{count}",
                other: "should be smaller than %{count}"
              },
              not_present: "should be set"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_max_value(10, %i[a b])
      end
    end

    record = model.new(a: 11, b: 12)

    assert_includes record.tap(&:valid?).errors[:a],
                    "must be smaller than 10"
    assert_includes record.tap(&:valid?).errors[:b],
                    "should be smaller than 10"
  end

  test "translates min value validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              min_value: {
                one: "should be greater than %{count}",
                other: "should be greater than %{count}"
              },
              not_present: "should be set"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_min_value(10, %i[a b])
      end
    end

    record = model.new(a: 9, b: 8)

    assert_includes record.tap(&:valid?).errors[:a],
                    "must be greater than 10"
    assert_includes record.tap(&:valid?).errors[:b],
                    "should be greater than 10"
  end

  test "translates not null validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              not_null: "should be set"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_not_null(%i[a b])
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a], "is required"
    assert_includes record.tap(&:valid?).errors[:b], "should be set"
  end

  test "translates presence validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              not_present: "should be set"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_presence(%i[a b])
      end
    end

    record = model.new

    assert_includes record.tap(&:valid?).errors[:a], "is required"
    assert_includes record.tap(&:valid?).errors[:b], "should be set"
  end

  test "translates no null byte validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              no_null_byte: "should not have a null byte"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_no_null_byte(%i[a b])
      end
    end

    record = model.new(a: "\0", b: "\0")

    assert_includes record.tap(&:valid?).errors[:a], "contains a null byte"
    assert_includes record.tap(&:valid?).errors[:b],
                    "should not have a null byte"
  end

  test "translates type validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              type: "should be %{type}"
            }
          }
        }
      }
    )

    model = create_model do
      attr_accessor :a, :b

      def validate
        super
        validates_type(String, %i[a b])
      end
    end

    record = model.new(a: 1, b: 0)

    assert_includes record.tap(&:valid?).errors[:a], "must be string"
    assert_includes record.tap(&:valid?).errors[:b], "should be string"
  end

  test "translates unique validation" do
    store_translations(
      :en,
      sequel: {
        errors: {
          user: {
            b: {
              unique: "is not available"
            }
          }
        }
      }
    )

    model = create_model do
      def validate
        super
        validates_unique(:a, :b)
      end
    end

    model.create(a: 1, b: 0)
    model.create(a: 0, b: 1)

    record = model.new(a: 1, b: 1)

    assert_includes record.tap(&:valid?).errors[:a], "is already taken"
    assert_includes record.tap(&:valid?).errors[:b], "is not available"
  end
end
