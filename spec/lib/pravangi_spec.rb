require 'spec_helper'

describe Pravangi do

  before(:all) do

    ActiveRecord::Base.establish_connection({ 
      adapter: :sqlite3,
      database: ':memory:'
      })

    ActiveRecord::Schema.define do
      create_table :posts do |table|
        table.column :title, :string
        table.column :body, :string
        table.column :created_at, :datetime
        table.column :updated_at, :datetime
      end

      CreatePendingApprovals.new.change
    end

    class Post < ActiveRecord::Base
      requires_approval if: :approved?

      def approved?
        true
      end
    end

  end

  context 'new record' do

    let(:post) { Post.create(title: 'metaware') }

    it 'should create a new record without any approval' do
      expect(post.title).to eq('metaware')
    end

  end

  context 'existing record' do

    let(:post) { Post.create(title: 'metaware') }

    before(:each) do
      post.title = 'new metaware'
    end

    context 'requires approval' do

      it 'doesnt update or change the record that requires approval' do
        post.save
        post.reload

        expect(post.title).to eq('metaware')
      end

      it 'saves a single record that contains pending changes' do
        post.save
        post.reload

        expect(post.title).to eq('metaware')
        expect(post.pending_approvals).to be_present
      end
      
    end

    context 'does not requires approval' do

      it 'should not stage changes when if condition is not satisfied' do
        expect(post).to receive(:approved?).and_return(false)
        
        post.save
        post.reload

        expect(post.title).to eq('new metaware')
      end

    end

  end

end