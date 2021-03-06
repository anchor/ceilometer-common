--
-- Copyright © 2013-2015 Anchor Systems, Pty Ltd and Others
--
-- The code in this file, and the program it is a part of, is
-- made available to you by its authors as open source software:
-- you can redistribute it and/or modify it under the terms of
-- the 3-clause BSD licence.
--
-- /Description/
-- This module exports the public-facing Ceilometer types
-- and the interface for them.
--
{-# LANGUAGE DeriveFoldable    #-}
{-# LANGUAGE DeriveFunctor     #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE TypeOperators     #-}

{-# OPTIONS -fno-warn-unused-binds #-}

module Ceilometer.Types
  ( -- * Payload Raws
    PRSimple(PRSimple), prSimple
  , PRCompoundEvent(PRCompoundEvent), prCompoundEvent
  , PRCompoundPollster(PRCompoundPollster), prCompoundPollster

    -- * Payload Decoded Fields
  , PFValue, PFValue64, PFValue32, PFValueText
  , PFEndpoint(..), pfEndpoint
  , PFVolumeStatus(..), pfVolumeStatus
  , PFVolumeVerb(..), pfVolumeVerb
  , PFInstanceStatus(..), pfInstanceStatus
  , PFImageStatus(..), pfImageStatus
  , PFImageVerb(..), pfImageVerb
  , PFSnapshotStatus(..), pfSnapshotStatus
  , PFSnapshotVerb(..), pfSnapshotVerb
  , PFIPStatus(..), pfIPStatus
  , PFIPVerb(..), pfIPVerb
  , PFIPAlloc(..), pfIPAlloc

    -- * Payload Decoded Points
  , PDVolume(PDVolume), pdVolume
  , PDSSD(PDSSD), pdSSD
  , PDCPU(PDCPU), pdCPU
  , PDDiskRead(..), pdDiskRead
  , PDDiskWrite(..), pdDiskWrite
  , PDNeutronTx(..), pdNeutronTx
  , PDNeutronRx(..), pdNeutronRx
  , PDInstanceVCPU(PDInstanceVCPU), pdInstanceVCPU
  , PDInstanceRAM(PDInstanceRAM), pdInstanceRAM
  , PDInstanceDisk(PDInstanceDisk), pdInstanceDisk
  , PDInstanceFlavor(PDInstanceFlavor), pdInstanceFlavor
  , PDImage(PDImage), pdImage
  , PDImagePollster(PDImagePollster), pdImagePollster
  , PDSnapshot(PDSnapshot), pdSnapshot
  , PDIP(PDIP), pdIP

    -- * Values
  , Valued, value
  , Timed(Timed), time

    -- * Interface
  , Env(..), Filters(..)
  , Flavor, FlavorMap
  , siphashID
  , filterByInstanceStatus
  ) where

import           Control.Applicative
import           Control.Lens              hiding (Fold, Simple)
import           Data.Binary               (Word64)
import           Data.Foldable

import           Ceilometer.Types.Base
import           Ceilometer.Types.CPU
import           Ceilometer.Types.Disk
import           Ceilometer.Types.Image
import           Ceilometer.Types.Instance
import           Ceilometer.Types.IP
import           Ceilometer.Types.Neutron
import           Ceilometer.Types.Snapshot
import           Ceilometer.Types.Volume
import           Vaultaire.Types


--------------------------------------------------------------------------------

-- | Information needed to parse/fold Ceilometer types, supplied by users.
--
data Env = Env { _flavormap  :: FlavorMap
               , _sourcedict :: SourceDict
               , _filters    :: Filters
               , _start      :: TimeStamp
               , _end        :: TimeStamp }

data Filters = Filters {
    instanceStatusFilter :: PFInstanceStatus -> Bool
}

filterByInstanceStatus :: Filters -> (a -> PFInstanceStatus) -> a -> Bool
filterByInstanceStatus (Filters f) g = f . g

--------------------------------------------------------------------------------

-- | Values with a TimeStamp.
--
data Timed value = Timed { _time :: !Word64, _val :: value }
     deriving (Show, Functor, Foldable, Traversable)

makeLenses ''Timed

-- | A family of lens that allows viewing/updating the payload value of decoded
--   Ceilometer points.
--
--   note: this is a Lens and not just a Getter since we wish to reuse the logic
--         for collector (making the points) and user (reading the points).
--
class Valued a where
  type PFValue a
  value :: Lens' a (PFValue a)

instance Valued a => Valued (Timed a) where
  type PFValue (Timed a)         = PFValue a
  value f (Timed t x)            = Timed t <$> value f x

instance Valued PDCPU            where
  type PFValue PDCPU             = PFValue64
  value f (PDCPU x)              = PDCPU <$> f x

instance Valued PDDiskRead       where
  type PFValue PDDiskRead        = PFValue64
  value f (PDDiskRead x)         = PDDiskRead <$> f x

instance Valued PDDiskWrite      where
  type PFValue PDDiskWrite       = PFValue64
  value f (PDDiskWrite x)        = PDDiskWrite <$> f x

instance Valued PDNeutronTx      where
  type PFValue PDNeutronTx       = PFValue64
  value f (PDNeutronTx x)        = PDNeutronTx <$> f x

instance Valued PDNeutronRx      where
  type PFValue PDNeutronRx       = PFValue64
  value f (PDNeutronRx x)        = PDNeutronRx <$> f x

instance Valued PDVolume         where
  type PFValue PDVolume          = PFValue32
  value f (PDVolume a b c x)     = PDVolume a b c <$> f x

instance Valued PDSSD            where
  type PFValue PDSSD             = PFValue32
  value f (PDSSD a b c x)        = PDSSD a b c <$> f x

instance Valued PDInstanceFlavor where
  type PFValue PDInstanceFlavor  = PFValueText
  value f (PDInstanceFlavor s x) = PDInstanceFlavor s <$> f x

instance Valued PDInstanceVCPU   where
  type PFValue PDInstanceVCPU    = PFValue32
  value f (PDInstanceVCPU s x)   = PDInstanceVCPU s <$> f x

instance Valued PDInstanceRAM    where
  type PFValue PDInstanceRAM     = PFValue32
  value f (PDInstanceRAM s x)    = PDInstanceRAM s <$> f x

instance Valued PDInstanceDisk   where
  type PFValue PDInstanceDisk    = PFValue32
  value f (PDInstanceDisk s x)   = PDInstanceDisk s <$> f x

instance Valued PDImage          where
  type PFValue PDImage           = PFValue32
  value f (PDImage s v e x)      = PDImage s v e <$> f x

instance Valued PDImagePollster  where
  type PFValue PDImagePollster   = PFValue64
  value f (PDImagePollster x)    = PDImagePollster <$> f x

instance Valued PDSnapshot       where
  type PFValue PDSnapshot        = PFValue32
  value f (PDSnapshot a b c x)   = PDSnapshot a b c <$> f x

instance Valued PDIP             where
  type PFValue PDIP              = PFIPAlloc
  value f (PDIP a b c x)         = PDIP a b c <$> f x
