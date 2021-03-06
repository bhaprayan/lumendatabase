require 'spec_helper'

describe Work do
  it { should have_and_belong_to_many :notices }
  it { should have_and_belong_to_many :infringing_urls }
  it { should have_and_belong_to_many :copyrighted_urls }

  context 'automatic validations' do
    it { should ensure_length_of(:kind).is_at_most(255) }
  end

  context '.unknown' do
    it "provides an unknown work" do
      work = Work.unknown

      expect(work.kind).to eq :unknown
      expect(work.description).to eq Work::UNKNOWN_WORK_DESCRIPTION
    end

    it "caches the unknown work" do
      work_1 = Work.unknown
      work_2 = Work.unknown

      expect(work_1).to eq work_2
    end
  end

  context '#infringing_urls' do
    it "does not create duplicate infringing_urls" do
      existing_infringing_url = create(
        :infringing_url, url: 'http://www.example.com/infringe'
      )
      duplicate_infringing_url = build(
        :infringing_url, url: 'http://www.example.com/infringe'
      )
      new_infringing_url = build(
        :infringing_url, url: 'http://example.com/new'
      )

      work = build(
        :work,
        infringing_urls: [duplicate_infringing_url, new_infringing_url]
      )
      work.save

      work.reload

      expect(work.infringing_urls).to include existing_infringing_url
      expect(InfringingUrl.count).to eq 2
    end
  end

  context '#copyrighted_urls' do
    it "does not create duplicate copyrighted_urls" do
      existing_copyrighted_url = create(
        :copyrighted_url, url: 'http://www.example.com/copyrighted'
      )
      duplicate_copyrighted_url = build(
        :copyrighted_url, url: 'http://www.example.com/copyrighted'
      )
      new_copyrighted_url = build(
        :copyrighted_url, url: 'http://example.com/new'
      )

      work = build(
        :work,
        copyrighted_urls: [duplicate_copyrighted_url, new_copyrighted_url]
      )
      work.save

      work.reload

      expect(work.copyrighted_urls).to include existing_copyrighted_url
      expect(CopyrightedUrl.count).to eq 2
    end
  end

  context '#kind' do
    it "auto classifies before saving if kind is not set" do
      work = build(:work)

      work.save
      expect(work.kind).to eq 'Unspecified'
    end

    it "does not auto classify if kind is set" do
      DeterminesWorkKind.any_instance.should_not_receive(:kind)
      work = build(:work, kind: 'foo')

      work.save
    end
  end

  it "validates infringing urls correctly when multiple are used at once" do
    notice = notice_with_works_attributes([
      { infringing_urls_attributes: [{ url: "this is not a url" }] },
      { infringing_urls_attributes: [{ url: "this is also not a url" }] }
    ])

    expect(notice).not_to be_valid
    expect(notice.errors.messages).to eq(
      { :"works.infringing_urls" => ["is invalid"] }
    )
  end

  it "validates copyrighted urls correctly when multiple are used at once" do
    notice = notice_with_works_attributes([
      { copyrighted_urls_attributes: [{ url: "this is not a url" }] },
      { copyrighted_urls_attributes: [{ url: "this is also not a url" }] }
    ])

    expect(notice).not_to be_valid
    expect(notice.errors.messages).to eq(
      { :"works.copyrighted_urls" => ["is invalid"] }
    )
  end

  private

  def notice_with_works_attributes(attributes)
    DMCA.new(
      works_attributes: attributes,
      entity_notice_roles_attributes: [{
        name: 'recipient',
        entity_attributes: { name: 'Recipient' }
      }]
    )
  end
end
