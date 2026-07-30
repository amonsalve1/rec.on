"""swipes

Revision ID: c4d81a29e6f0
Revises: 7b05021fd327

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'c4d81a29e6f0'
down_revision = '7b05021fd327'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('swipes',
    sa.Column('party_id', sa.BigInteger(), nullable=False),
    sa.Column('option_id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=False),
    sa.Column('liked', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['party_id'], ['parties.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(
        ['party_id', 'option_id'],
        ['options.party_id', 'options.id'],
        name='fk_swipes_party_option',
        ondelete='CASCADE',
    ),
    sa.PrimaryKeyConstraint('party_id', 'option_id', 'user_id')
    )
    op.create_index('ix_swipes_party_user', 'swipes', ['party_id', 'user_id'], unique=False)


def downgrade():
    op.drop_index('ix_swipes_party_user', table_name='swipes')
    op.drop_table('swipes')
