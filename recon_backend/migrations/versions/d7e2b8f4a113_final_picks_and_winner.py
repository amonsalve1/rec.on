"""final picks and winner

Revision ID: d7e2b8f4a113
Revises: c4d81a29e6f0

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'd7e2b8f4a113'
down_revision = 'c4d81a29e6f0'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('final_picks',
    sa.Column('party_id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=False),
    sa.Column('option_id', sa.BigInteger(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['party_id'], ['parties.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(
        ['party_id', 'option_id'],
        ['options.party_id', 'options.id'],
        name='fk_final_picks_party_option',
        ondelete='CASCADE',
    ),
    sa.PrimaryKeyConstraint('party_id', 'user_id')
    )
    op.add_column('parties', sa.Column('winner_option_id', sa.BigInteger(), nullable=True))
    op.create_foreign_key(
        'fk_parties_winner_option',
        'parties',
        'options',
        ['winner_option_id'],
        ['id'],
        ondelete='SET NULL',
    )


def downgrade():
    op.drop_constraint('fk_parties_winner_option', 'parties', type_='foreignkey')
    op.drop_column('parties', 'winner_option_id')
    op.drop_table('final_picks')
