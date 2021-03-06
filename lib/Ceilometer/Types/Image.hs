--
-- Copyright © 2013-2015 Anchor Systems, Pty Ltd and Others
--
-- The code in this file, and the program it is a part of, is
-- made available to you by its authors as open source software:
-- you can redistribute it and/or modify it under the terms of
-- the 3-clause BSD licence.
--
-- /Description/
-- This module defines the Ceilometer Image type.
--
{-# LANGUAGE MultiWayIf        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

module Ceilometer.Types.Image
  ( -- * Fields
    PFImageStatus(..), pfImageStatus
  , PFImageVerb(..), pfImageVerb
  , PDImage(..), pdImage
  , PDImagePollster(..), pdImagePollster
  , imageStatus, imageVerb, imageVal
  ) where

import           Control.Applicative
import           Control.Lens
import           Data.Binary           (Word8)
import           Data.Text             (Text)

import           Ceilometer.Types.Base
import           Ceilometer.Types.TH
import           Vaultaire.Types

$(declarePF    "Image"
              ("Status", ''Word8)
            [ ("Active"       , 1)
            , ("Saving"       , 2)
            , ("Deleted"      , 3)
            , ("Queued"       , 4)
            , ("PendingDelete", 5)
            , ("Killed"       , 6) ]
            [ ''Show, ''Read, ''Eq, ''Bounded, ''Enum ])

$(declarePF    "Image"
              ("Verb", ''Word8)
            [ ("Serve"   , 1)
            , ("Update"  , 2)
            , ("Upload"  , 3)
            , ("Download", 4)
            , ("Delete"  , 5) ]
            [ ''Show, ''Read, ''Eq, ''Bounded, ''Enum ])

data PDImage = PDImage
  { _imageStatus   :: PFImageStatus
  , _imageVerb     :: PFImageVerb
  , _imageEndpoint :: PFEndpoint
  , _imageVal      :: PFValue32 }
  deriving (Eq, Show, Read)

$(makeLenses ''PDImage)

pdImage :: Prism' PRCompoundEvent PDImage
pdImage = prism' pretty parse
  where parse raw
          =   PDImage
          <$> (raw ^? eventStatus   . pfImageStatus)
          <*> (raw ^? eventVerb     . pfImageVerb)
          <*> (raw ^? eventEndpoint . pfEndpoint)
          <*> (raw ^? eventVal )
        pretty (PDImage status verb ep val)
          = PRCompoundEvent
            val
            (ep     ^. re pfEndpoint)
            (verb   ^. re pfImageVerb)
            (status ^. re pfImageStatus)

newtype PDImagePollster = PDImagePollster { _pdImagePollsterVal :: PFValue64 }
     deriving (Show, Read, Eq)

pdImagePollster :: Iso' PRSimple PDImagePollster
pdImagePollster = iso (PDImagePollster . _prSimpleVal) (PRSimple . _pdImagePollsterVal)
