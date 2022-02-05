
require 'spec_helper'

RSpec.describe Yoda::Services::CodeCompletion::ConstProvider do
  let(:provider) { described_class.new(project.environment, ast, location, evaluator) }

  let(:project) { Yoda::Store::Project.for_path(nil) }
  let(:ast) { Yoda::Parsing.parse(source) }
  let(:evaluator) { Yoda::Services::Evaluator.new(environment: project.environment, ast: ast) }

  before do
    project.setup
    ReadSourceHelper.read_source(project: project, source: source) if source
  end

  def range(b, e)
    b_row, b_column = b
    e_row, e_column = e
    have_attributes(
      begin_location: have_attributes(row: b_row, column: b_column),
      end_location: have_attributes(row: e_row, column: e_column),
    )
  end

  describe '#candidates' do
    subject { provider.candidates }

    context 'in top level' do
      context 'with unscoped constant' do
        let(:location) { Yoda::Parsing::Location.new(row: 2, column: 7) }
        let(:source) do
          <<~EOS
          class YodaFixture; end
          YodaFix
          EOS
        end

        it 'returns the matched top level constants' do
          expect(subject).to contain_exactly(
            have_attributes(edit_text: 'YodaFixture', title: 'YodaFixture', range: range([2, 0], [2, 7])),
          )
        end
      end

      context 'with unscoped constant' do
        let(:location) { Yoda::Parsing::Location.new(row: 5, column: 16) }
        let(:source) do
          <<~EOS
          class YodaFixture
            class Sample1; end
            module Sample2; end
          end
          YodaFixture::Sam
          EOS
        end

        it 'returns the matched constants on YodaFixture' do
          expect(subject).to contain_exactly(
            have_attributes(edit_text: 'Sample1', title: 'YodaFixture::Sample1', range: range([5, 13], [5, 16])),
            have_attributes(edit_text: 'Sample2', title: 'YodaFixture::Sample2', range: range([5, 13], [5, 16])),
          )
        end

        context 'index word is more shorter' do
          let(:source) do
            <<~EOS
            class YodaFixture
              class Sample1; end
              module Sample2; end
            end
            YodaFixture::S
            EOS
          end
          let(:location) { Yoda::Parsing::Location.new(row: 5, column: 14) }

          pending 'does not show constants of Object like SystemExit' do
            expect(subject).to contain_exactly(
              have_attributes(edit_text: 'Sample1', title: 'YodaFixture::Sample1', range: range([5, 13], [5, 16])),
              have_attributes(edit_text: 'Sample2', title: 'YodaFixture::Sample2', range: range([5, 13], [5, 16])),
            )
          end
        end
      end
    end

    context 'in class context' do
      context 'with unscoped constant' do
        let(:location) { Yoda::Parsing::Location.new(row: 3, column: 11) }
        let(:source) do
          <<~EOS
          class YodaFixture
            def example
              YodaFix
            end
          end
          class YodaFixture2; end
          EOS
        end

        it 'returns the matched top level constants' do
          expect(subject).to contain_exactly(
            have_attributes(edit_text: 'YodaFixture', title: 'YodaFixture', range: range([3, 4], [3, 11])),
            have_attributes(edit_text: 'YodaFixture2', title: 'YodaFixture2', range: range([3, 4], [3, 11])),
          )
        end

        context 'when the class has another constant' do
          let(:location) { Yoda::Parsing::Location.new(row: 3, column: 11) }
          let(:source) do
            <<~EOS
            class YodaFixture
              def example
                YodaFix
              end
              class YodaFixtureInner; end
            end
            class YodaFixture2; end
            EOS
          end

          it 'returns the matched constant of the current constant and top level constants' do
            expect(subject).to contain_exactly(
              have_attributes(edit_text: 'YodaFixture', title: 'YodaFixture', range: range([3, 4], [3, 11])),
              have_attributes(edit_text: 'YodaFixture2', title: 'YodaFixture2', range: range([3, 4], [3, 11])),
              have_attributes(edit_text: 'YodaFixtureInner', title: 'YodaFixture::YodaFixtureInner', range: range([3, 4], [3, 11])),
            )
          end
        end
      end

      context 'with scoped constant' do
        context 'when the class has another constant' do
          let(:location) { Yoda::Parsing::Location.new(row: 3, column: 20) }
          let(:source) do
            <<~EOS
            class YodaFixture
              def example
                YodaFixture::Inn
              end
              class Inner; end
            end
            class YodaFixture2; end
            EOS
          end

          it 'returns the matched constant on the scope' do
            expect(subject).to contain_exactly(
              have_attributes(edit_text: 'Inner', title: 'YodaFixture::Inner', range: range([3, 17], [3, 20])),
            )
          end
        end
      end

      context 'with top-level scope' do
        context 'when the class has another constant' do
          let(:location) { Yoda::Parsing::Location.new(row: 3, column: 13) }
          let(:source) do
            <<~EOS
            class YodaFixture
              def example
                ::YodaFix
              end
              class YodaFixtureInner; end
            end
            class YodaFixture2; end
            EOS
          end

          it 'returns the matched constant of the current constant and top level constants' do
            expect(subject).to contain_exactly(
              have_attributes(edit_text: 'YodaFixture', title: 'YodaFixture', range: range([3, 6], [3, 13])),
              have_attributes(edit_text: 'YodaFixture2', title: 'YodaFixture2', range: range([3, 6], [3, 13])),
            )
          end
        end
      end
    end
  end
end
