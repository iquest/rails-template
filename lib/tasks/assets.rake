# frozen_string_literal: true

unless Rake::Task.task_defined?("assets:clean")
  Rake::Task.define_task("assets:clean" => "webpacker:clean")
end
