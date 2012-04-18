require 'spec_helper'
require 'qless/queue'
require 'qless/job_reservers/ordered'

module Qless
  module JobReservers
    describe Ordered do
      describe "#reserve" do
        let(:q1) { fire_double("Qless::Queue") }
        let(:q2) { fire_double("Qless::Queue") }
        let(:q3) { fire_double("Qless::Queue") }
        let(:reserver) { Ordered.new([q1, q2, q3]) }

        it 'always pops jobs from the first queue as long as it has jobs' do
          q1.should_receive(:pop).and_return(:j1, :j2, :j3)
          q2.should_not_receive(:pop)
          q3.should_not_receive(:pop)

          reserver.reserve.should eq(:j1)
          reserver.reserve.should eq(:j2)
          reserver.reserve.should eq(:j3)
        end

        it 'falls back to other queues when earlier queues lack jobs' do
          call_count = 1
          q1.should_receive(:pop).exactly(4).times { :q1_job if [2, 4].include?(call_count) }
          q2.should_receive(:pop).exactly(2).times { :q2_job if call_count == 1 }
          q3.should_receive(:pop).once             { :q3_job if call_count == 3 }

          reserver.reserve.should eq(:q2_job)
          call_count = 2
          reserver.reserve.should eq(:q1_job)
          call_count = 3
          reserver.reserve.should eq(:q3_job)
          call_count = 4
          reserver.reserve.should eq(:q1_job)
        end

        it 'returns nil if none of the queues have jobs' do
          [q1, q2, q3].each { |q| q.stub(:pop) }
          reserver.reserve.should be_nil
        end
      end
    end
  end
end
